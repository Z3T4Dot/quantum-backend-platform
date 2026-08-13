# Quantum ERP — Business Engines Catalog

**Versión:** 0.2  
**Fecha:** 2026-08-04  
**Estado:** En definición — Sprint 5  
**Clasificación:** Referencia técnica interna — Brandex Global

> Este documento es el mapa de Quantum. Antes de implementar cualquier Engine, esta entrada debe existir aquí. Antes de activar una Capability en un módulo, debe estar definida aquí. La pregunta no es "¿qué servicio hacemos?" sino "¿este requerimiento pertenece a qué Engine, y está en el catálogo?".

---

## Jerarquía

```
Business Engine
      ↓
  Capabilities      ← definidas en este catálogo
      ↓
Business Contract   ← definidos en este catálogo
      ↓
Business Blueprint  ← definidos en este catálogo
      ↓
Module Configuration
      ↓
Business Module (Runtime)
```

---

## Esquemas

### Capability

```yaml
capability: CAPABILITY_NAME
version: 1
description: Una sola línea — qué hace esta Capability.

consumes:            # eventos de dominio que esta Capability escucha
  - domain.event.name

publishes:           # eventos de dominio que esta Capability emite
  - domain.event.name

requires:            # otras Capabilities que deben estar activas
  - OTHER_CAPABILITY

optional_with:       # Capabilities que la enriquecen pero no son obligatorias
  - ANOTHER_CAPABILITY
```

Reglas:
- `requires` forma un grafo de dependencias. Si un módulo activa `B` y `B` requiere `A`, `A` también debe estar activa.
- `optional_with` no crea dependencia — solo documenta integraciones conocidas.
- `version` sigue semver mayor: cuando cambia la interfaz o los eventos publicados, se incrementa.

### Business Contract

```yaml
contract: CONTRACT_NAME
engine: engine-service
version: 1
capabilities:        # subconjunto estable de Capabilities del Engine
  - CAPABILITY_A
  - CAPABILITY_B
```

### Business Blueprint

```yaml
blueprint: BLUEPRINT_NAME
version: 1
description: Una sola línea — qué problema de negocio representa esta composición.

contracts:           # Contracts que compone este Blueprint
  - engine: engine-a-service
    contract: v1
  - engine: engine-b-service
    contract: v1

used_by:             # Módulos que usan este Blueprint
  - MODULE_KEY
```

Reglas:
- Un Blueprint nunca implementa lógica — solo declara qué Contracts consume.
- Un módulo que necesite un único Engine puede omitir el Blueprint (usa el Contract directamente).
- Un módulo que combine múltiples Engines siempre debe hacerlo a través de un Blueprint.

---

## Índice de Engines

| Engine | Servicio | Capabilities definidas | Estado |
|--------|----------|----------------------|--------|
| [Inventory Engine](#inventory-engine) | `inventory-service` | 13 | Definición en progreso |
| [CRM Engine](#crm-engine) | `crm-service` | 5 | ⬜ Pendiente Sprint 5 |
| [Creative Engine](#creative-engine) | `creative-service` | 4 | ⬜ Pendiente Sprint 5 |
| [Manufacturing Engine](#manufacturing-engine) | `manufacturing-service` | 4 | ⬜ Pendiente Sprint 5 |
| [Service Engine](#service-engine) | `service-service` | 4 | ⬜ Pendiente Sprint 5 |
| [Finance Engine](#finance-engine) | `finance-service` | — | Deferred — ver ADR-008 |
| [Analytics Engine](#analytics-engine) | `analytics-service` | — | Deferred |

---

## Inventory Engine

**Servicio:** `inventory-service`  
**Responsabilidad:** Gestionar el ciclo de vida completo de activos físicos — registro, movimiento, asignación, disponibilidad, mantenimiento y trazabilidad — de forma genérica e independiente del tipo de negocio que los usa.

### Capabilities

---

```yaml
capability: ASSET_REGISTRY
version: 1
description: Registro canónico de activos físicos con atributos, categorías y metadatos.

consumes: []

publishes:
  - inventory.asset.created
  - inventory.asset.updated
  - inventory.asset.deleted

requires: []

optional_with:
  - QR_BARCODE
  - RFID
  - LIFECYCLE_TRACKING
```

---

```yaml
capability: ASSIGNMENT
version: 1
description: Asignación de activos a personas, proyectos o ubicaciones.

consumes: []

publishes:
  - inventory.asset.assigned
  - inventory.asset.unassigned

requires:
  - ASSET_REGISTRY

optional_with:
  - LIFECYCLE_TRACKING
  - QR_BARCODE
```

---

```yaml
capability: TRANSFER
version: 1
description: Movimiento de activos entre ubicaciones o almacenes con registro de origen y destino.

consumes: []

publishes:
  - inventory.asset.transferred

requires:
  - ASSET_REGISTRY

optional_with:
  - LIFECYCLE_TRACKING
  - QR_BARCODE
  - RFID
```

---

```yaml
capability: RESERVATION
version: 1
description: Reserva de activos para fechas futuras con control de disponibilidad y exclusión de conflictos.

consumes:
  - project.completed      # libera reservas activas del proyecto
  - project.cancelled      # libera reservas activas del proyecto

publishes:
  - inventory.asset.reserved
  - inventory.asset.reservation.released

requires:
  - ASSET_REGISTRY
  - AVAILABILITY_CALENDAR

optional_with:
  - LIFECYCLE_TRACKING
```

---

```yaml
capability: INSPECTION
version: 1
description: Registro de inspecciones de estado — entrada, salida, periódica — con resultado y evidencia.

consumes: []

publishes:
  - inventory.asset.inspection.completed

requires:
  - ASSET_REGISTRY

optional_with:
  - LIFECYCLE_TRACKING
  - QR_BARCODE
```

---

```yaml
capability: MAINTENANCE
version: 1
description: Órdenes de mantenimiento preventivo y correctivo con estados y cierre.

consumes: []

publishes:
  - inventory.maintenance.order.created
  - inventory.maintenance.order.completed

requires:
  - ASSET_REGISTRY
  - INSPECTION

optional_with:
  - LIFECYCLE_TRACKING
```

---

```yaml
capability: LIFECYCLE_TRACKING
version: 1
description: Historial inmutable de todos los eventos sobre un activo — quién, cuándo, qué.

consumes:
  - inventory.asset.assigned
  - inventory.asset.unassigned
  - inventory.asset.transferred
  - inventory.asset.reserved
  - inventory.asset.reservation.released
  - inventory.asset.inspection.completed
  - inventory.maintenance.order.created
  - inventory.maintenance.order.completed

publishes: []

requires:
  - ASSET_REGISTRY

optional_with: []
```

---

```yaml
capability: AVAILABILITY_CALENDAR
version: 1
description: Calendario de disponibilidad por activo, categoría y ubicación con ventanas de ocupación.

consumes:
  - inventory.asset.reserved
  - inventory.asset.reservation.released
  - inventory.asset.assigned
  - inventory.asset.unassigned

publishes:
  - inventory.availability.updated

requires:
  - ASSET_REGISTRY

optional_with: []
```

---

```yaml
capability: QR_BARCODE
version: 1
description: Generación y lectura de códigos QR y barcode para identificación física de activos.

consumes: []

publishes: []

requires:
  - ASSET_REGISTRY

optional_with:
  - ASSIGNMENT
  - TRANSFER
  - INSPECTION
```

---

```yaml
capability: RFID
version: 1
description: Integración con lectores RFID para inventario masivo sin línea de visión.

consumes: []

publishes: []

requires:
  - ASSET_REGISTRY

optional_with:
  - TRANSFER
  - BATCH_OPERATIONS
```

---

```yaml
capability: KITS
version: 1
description: Agrupación de activos individuales en kits reutilizables que se gestionan como unidad.

consumes: []

publishes:
  - inventory.kit.created
  - inventory.kit.assembled
  - inventory.kit.disassembled

requires:
  - ASSET_REGISTRY

optional_with:
  - QR_BARCODE
  - RFID
```

---

```yaml
capability: BATCH_OPERATIONS
version: 1
description: Ejecución de operaciones sobre múltiples activos simultáneamente como unidad atómica.

consumes: []

publishes: []

requires:
  - ASSET_REGISTRY

optional_with:
  - TRANSFER
  - ASSIGNMENT
  - INSPECTION
  - RFID
```

---

```yaml
capability: AUDIT_TRAIL
version: 1
description: Registro inmutable y firmado de todos los cambios de estado sobre cualquier activo.

consumes:
  - inventory.asset.created
  - inventory.asset.updated
  - inventory.asset.deleted
  - inventory.asset.assigned
  - inventory.asset.unassigned
  - inventory.asset.transferred
  - inventory.asset.reserved
  - inventory.asset.reservation.released

publishes: []

requires:
  - ASSET_REGISTRY

optional_with: []
```

---

### Business Contracts

| Versión | Estado | Capabilities incluidas |
|---------|--------|------------------------|
| `v1` | Borrador (Sprint 6) | `ASSET_REGISTRY`, `ASSIGNMENT`, `TRANSFER`, `RESERVATION`, `INSPECTION`, `QR_BARCODE`, `KITS`, `AUDIT_TRAIL`, `AVAILABILITY_CALENDAR` |

### Módulos actuales

```yaml
module: KEEPME
name: "KeepMe — Renta de Equipo"
engine: INVENTORY
contract: v1
uses:
  - ASSET_REGISTRY
  - ASSIGNMENT
  - TRANSFER
  - INSPECTION
  - QR_BARCODE
  - KITS
  - AUDIT_TRAIL
status: planned  # Sprint 7
```

```yaml
module: CELEBRATE
name: "Celebrate — Eventos Especiales"
engine: INVENTORY
contract: v1
uses:
  - ASSET_REGISTRY
  - TRANSFER
  - RESERVATION
  - AVAILABILITY_CALENDAR
status: pending
```

```yaml
module: CUSTOMX
name: "CustomX — Producción de Experiencias"
engine: INVENTORY
contract: v1
uses:
  - ASSET_REGISTRY
  - ASSIGNMENT
  - TRANSFER
  - INSPECTION
  - MAINTENANCE
  - RESERVATION
  - AUDIT_TRAIL
status: pending
```

---

## CRM Engine

**Servicio:** `crm-service`  
**Responsabilidad:** Gestionar el ciclo de vida de la relación comercial — desde el primer contacto hasta el cierre de un deal.

### Capabilities

```yaml
capability: CONTACT_MANAGEMENT
version: 1
description: Registro y gestión de contactos y empresas con atributos y categorización.
consumes: []
publishes:
  - crm.contact.created
  - crm.contact.updated
requires: []
optional_with:
  - ACTIVITY_LOG
  - EMAIL_INTEGRATION
```

```yaml
capability: PIPELINE
version: 1
description: Pipeline visual de oportunidades con etapas configurables y reglas de transición.
consumes: []
publishes:
  - crm.deal.stage.changed
requires:
  - CONTACT_MANAGEMENT
optional_with:
  - DEAL_TRACKING
```

```yaml
capability: DEAL_TRACKING
version: 1
description: Seguimiento de deals con valor, probabilidad de cierre y fecha estimada.
consumes: []
publishes:
  - crm.deal.won
  - crm.deal.lost
requires:
  - PIPELINE
optional_with:
  - ACTIVITY_LOG
```

```yaml
capability: ACTIVITY_LOG
version: 1
description: Registro de actividades — llamadas, emails, reuniones — por contacto o deal.
consumes: []
publishes:
  - crm.activity.created
requires:
  - CONTACT_MANAGEMENT
optional_with:
  - EMAIL_INTEGRATION
```

```yaml
capability: EMAIL_INTEGRATION
version: 1
description: Sincronización de emails entrantes y salientes con contactos y deals.
consumes: []
publishes: []
requires:
  - CONTACT_MANAGEMENT
optional_with:
  - ACTIVITY_LOG
```

### Business Contracts

| Versión | Estado |
|---------|--------|
| `v1` | ⬜ Borrador (Sprint 5) |

### Módulos actuales

```yaml
module: CONNECTME
name: "ConnectMe — CRM Comercial"
engine: CRM
contract: v1
uses:
  - CONTACT_MANAGEMENT
  - PIPELINE
  - DEAL_TRACKING
  - ACTIVITY_LOG
  - EMAIL_INTEGRATION
status: pending
```

---

## Creative Engine

**Servicio:** `creative-service`  
**Responsabilidad:** Gestionar el ciclo de vida de entregables creativos — briefing, producción, revisiones y aprobaciones.

### Capabilities

```yaml
capability: BRIEF_MANAGEMENT
version: 1
description: Creación y seguimiento de briefs creativos con alcance, referencias y aprobador.
consumes: []
publishes:
  - creative.brief.created
requires: []
optional_with:
  - APPROVAL_WORKFLOW
```

```yaml
capability: DELIVERABLE_TRACKING
version: 1
description: Registro de entregables con versiones, estados y fecha de entrega.
consumes: []
publishes:
  - creative.deliverable.submitted
  - creative.deliverable.approved
  - creative.deliverable.rejected
requires:
  - BRIEF_MANAGEMENT
optional_with:
  - VERSION_CONTROL
  - APPROVAL_WORKFLOW
  - FEEDBACK_THREADS
```

```yaml
capability: APPROVAL_WORKFLOW
version: 1
description: Flujos de aprobación configurables en una o varias etapas con notificaciones.
consumes: []
publishes:
  - creative.approval.completed
requires:
  - DELIVERABLE_TRACKING
optional_with: []
```

```yaml
capability: FEEDBACK_THREADS
version: 1
description: Hilos de feedback por entregable y versión con historial de revisiones.
consumes: []
publishes: []
requires:
  - DELIVERABLE_TRACKING
optional_with: []
```

### Business Contracts

| Versión | Estado |
|---------|--------|
| `v1` | ⬜ Borrador (Sprint 5) |

---

## Manufacturing Engine

**Servicio:** `manufacturing-service`  
**Responsabilidad:** Gestionar la producción de bienes físicos o ensamblajes — BOMs, órdenes de trabajo y trazabilidad de manufactura.

### Capabilities

```yaml
capability: BOM_MANAGEMENT
version: 1
description: Bill of Materials — estructura jerárquica de materiales por producto o ensamblaje.
consumes: []
publishes:
  - manufacturing.bom.created
  - manufacturing.bom.updated
requires: []
optional_with:
  - WORK_ORDERS
```

```yaml
capability: WORK_ORDERS
version: 1
description: Órdenes de trabajo con etapas, asignaciones, tiempo estimado y seguimiento de estado.
consumes: []
publishes:
  - manufacturing.work_order.created
  - manufacturing.work_order.completed
requires:
  - BOM_MANAGEMENT
optional_with:
  - MATERIAL_REQUISITION
  - QUALITY_CONTROL
```

```yaml
capability: MATERIAL_REQUISITION
version: 1
description: Solicitud de materiales contra el inventario para cubrir una orden de trabajo.
consumes: []
publishes:
  - manufacturing.material.requested
requires:
  - WORK_ORDERS
optional_with: []
```

```yaml
capability: QUALITY_CONTROL
version: 1
description: Puntos de control de calidad en el proceso productivo con criterios y registro de resultado.
consumes: []
publishes:
  - manufacturing.qc.passed
  - manufacturing.qc.failed
requires:
  - WORK_ORDERS
optional_with: []
```

### Business Contracts

| Versión | Estado |
|---------|--------|
| `v1` | ⬜ Borrador (Sprint 5) |

---

## Service Engine

**Servicio:** `service-service`  
**Responsabilidad:** Gestionar la prestación de servicios en campo — asignación de personas, planificación, check-in/check-out y cierre.

### Capabilities

```yaml
capability: STAFF_ASSIGNMENT
version: 1
description: Asignación de personas a servicios o jornadas con control de disponibilidad.
consumes: []
publishes:
  - service.staff.assigned
  - service.staff.unassigned
requires: []
optional_with:
  - SCHEDULING
```

```yaml
capability: SCHEDULING
version: 1
description: Planificación de calendarios de servicio con visibilidad de carga por persona.
consumes: []
publishes:
  - service.schedule.created
requires:
  - STAFF_ASSIGNMENT
optional_with: []
```

```yaml
capability: FIELD_CHECKIN
version: 1
description: Check-in y check-out del personal en campo con marca de tiempo y ubicación.
consumes: []
publishes:
  - service.staff.checked_in
  - service.staff.checked_out
requires:
  - STAFF_ASSIGNMENT
optional_with:
  - TIMESHEET
```

```yaml
capability: SERVICE_REPORT
version: 1
description: Reporte de cierre de servicio con evidencia fotográfica, observaciones y firma.
consumes: []
publishes:
  - service.report.submitted
requires:
  - FIELD_CHECKIN
optional_with: []
```

### Business Contracts

| Versión | Estado |
|---------|--------|
| `v1` | ⬜ Borrador (Sprint 5) |

---

## Finance Engine

**Servicio:** `finance-service`  
**Estado:** Deferred — ver ADR-008. El alcance debe definirse formalmente antes de cualquier Capability.

---

## Analytics Engine

**Servicio:** `analytics-service`  
**Estado:** Deferred. Analytics no produce datos — los consume. Es el único Engine que depende del catálogo de eventos de todos los demás.

---

## Grafo de dependencias entre Capabilities (Inventory Engine)

```
ASSET_REGISTRY ←── ASSIGNMENT
               ←── TRANSFER
               ←── INSPECTION ←── MAINTENANCE
               ←── QR_BARCODE
               ←── RFID
               ←── KITS
               ←── BATCH_OPERATIONS
               ←── AUDIT_TRAIL
               ←── LIFECYCLE_TRACKING
               ←── AVAILABILITY_CALENDAR ←── RESERVATION
```

`ASSET_REGISTRY` es la raíz del árbol de dependencias del Inventory Engine. Todo módulo que active cualquier otra Capability debe activar `ASSET_REGISTRY`.

---

## Business Blueprints

Un Blueprint compone uno o varios Contracts. Lo usa el Business Runtime para construir el pipeline de ejecución de un módulo. Un módulo que opere sobre un único Engine puede omitir el Blueprint y referenciar el Contract directamente; un módulo que combine múltiples Engines siempre necesita un Blueprint.

---

```yaml
blueprint: INVENTORY_ONLY
version: 1
description: Módulos que operan exclusivamente sobre el Inventory Engine.

contracts:
  - engine: inventory-service
    contract: v1

used_by:
  - KEEPME
  - CELEBRATE
  - CUSTOMX
```

---

```yaml
blueprint: OPERATIONAL_BLUEPRINT
version: 1
description: >
  Módulos que operan con activos físicos, personal en campo y planificación
  de proyectos de forma simultánea.

contracts:
  - engine: inventory-service
    contract: v1
  - engine: service-service
    contract: v1
  - engine: project-service
    contract: v1

used_by: []
```

---

```yaml
blueprint: CAMPAIGN_BLUEPRINT
version: 1
description: >
  Módulos que combinan pipeline comercial, producción de contenido creativo
  y planificación de proyecto en un solo flujo de trabajo.

contracts:
  - engine: crm-service
    contract: v1
  - engine: creative-service
    contract: v1
  - engine: project-service
    contract: v1

used_by: []
```

---

## Business Runtime

El Business Runtime es la pieza de la plataforma que une el mundo del módulo con el mundo del Engine. Ningún módulo habla directamente con un Engine.

```
Business Module
      ↓  declara
Module Configuration   (qué Blueprint usa + qué Capabilities activa)
      ↓  procesada por
Business Runtime       (lee configuración, valida dependencias, construye pipeline)
      ↓  según
Business Blueprint     (qué Contracts están disponibles)
      ↓  via
Business Contract      (interfaz del Engine)
      ↓  ejecuta en
Business Engine
```

**Responsabilidades del Runtime:**

1. Leer la Module Configuration y resolver el Blueprint referenciado.
2. Validar que las Capabilities declaradas existen en los Contracts del Blueprint.
3. Verificar que el grafo de `requires` está satisfecho (si `TRANSFER` está activo, `ASSET_REGISTRY` también debe estarlo).
4. Construir el pipeline de ejecución con solo las Capabilities activas.
5. Enrutar cada petición al Engine correcto según el Contract.

**El Engine recibe peticiones del Runtime, no del módulo.** El módulo nunca conoce qué Engine procesa su operación — solo conoce su configuración.

> El Business Runtime es el componente que convierte el catálogo declarativo (Capabilities + Blueprints) en comportamiento ejecutable. Es también el punto de extensión natural para Capability Discovery (ADR-014): cuando exista una capa de validación en tiempo de carga, vivirá aquí.

---

## Reglas del catálogo

1. Ningún Engine se implementa sin estar definido aquí.
2. Los nombres comerciales (KeepMe, ConnectMe) nunca aparecen en el código de un Engine — solo en las declaraciones de módulo.
3. Una Capability nueva requiere actualización de este catálogo antes de implementarse.
4. Un módulo nuevo se registra aquí con `status: planned` antes de escribir su primera línea de configuración.
5. Un nuevo Business Contract requiere un ADR que documente qué Capabilities expone.
6. Un nuevo Business Blueprint requiere actualización de este catálogo con su composición y la lista de módulos que lo consumen.
7. Si `requires` de una Capability A apunta a B, y B no está en el catálogo, ese es un error de definición — no de implementación.
8. El Business Runtime nunca se modifica para añadir lógica de un Engine específico — eso viola P-ENG-001.

---

*Catálogo vivo. Versión 0.3 — Sprint 5. Actualizar con cada nueva Capability, Contract, Blueprint o módulo.*
