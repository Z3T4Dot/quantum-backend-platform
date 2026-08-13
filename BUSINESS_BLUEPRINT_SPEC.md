# Quantum ERP — Business Blueprint Specification

**Versión:** 1.0  
**Fecha:** 2026-08-04  
**Estado:** Especificación oficial  
**Clasificación:** Referencia técnica interna — Brandex Global

> Este documento define el lenguaje oficial de declaración de módulos de Quantum. Un Business Module se declara enteramente mediante este formato. No hay código, no hay implementación: solo la declaración. El Business Runtime la lee, la valida y construye el pipeline de ejecución.

---

## Índice

1. [Propósito](#1-propósito)
2. [Estructura raíz](#2-estructura-raíz)
3. [Schema completo](#3-schema-completo)
   - [module](#31-module)
   - [metadata](#32-metadata)
   - [blueprint](#33-blueprint)
   - [engines](#34-engines)
   - [contracts](#35-contracts)
   - [capabilities](#36-capabilities)
   - [workflows](#37-workflows)
   - [events](#38-events)
   - [permissions](#39-permissions)
   - [configuration](#310-configuration)
   - [ui](#311-ui)
4. [Ejemplos completos](#4-ejemplos-completos)
5. [Reglas de validación](#5-reglas-de-validación)
6. [Procesamiento por el Business Runtime](#6-procesamiento-por-el-business-runtime)
7. [Versionado de Blueprints](#7-versionado-de-blueprints)
8. [Gobernanza](#8-gobernanza)

---

## 1. Propósito

Un Business Module es la instancia comercial de uno o varios Business Engines. Hasta ahora definirlo requería código: configuración Spring, beans condicionales, flags de feature. En Quantum, un módulo se define con una sola declaración YAML — su Business Blueprint.

El Business Blueprint responde cinco preguntas sobre un módulo:

| Pregunta | Clave en el schema |
|----------|--------------------|
| ¿Qué es este módulo? | `module`, `metadata` |
| ¿Qué Engines y Contracts usa? | `blueprint` / `engines` + `contracts` |
| ¿Qué Capabilities activa? | `capabilities` |
| ¿Qué eventos publica y consume? | `events` |
| ¿Cómo se comporta en el contexto de la plataforma? | `workflows`, `permissions`, `configuration`, `ui` |

---

## 2. Estructura raíz

```yaml
module:
  id: string              # requerido — identificador único del módulo

metadata:                 # requerido
  ...

blueprint: string         # opcional — referencia a un Blueprint del catálogo
                          # si se omite, se declara la composición inline

engines:                  # requerido si no hay `blueprint`
  - string

contracts:                # requerido
  ...

capabilities:             # requerido
  ...

workflows:                # opcional
  ...

events:                   # requerido si el módulo publica o consume eventos
  ...

permissions:              # requerido
  - string

configuration:            # opcional — parámetros específicos del módulo
  ...

ui:                       # opcional
  ...
```

---

## 3. Schema completo

### 3.1 `module`

```yaml
module:
  id: string              # snake_case, único en la plataforma
  version: string         # semver — versión de esta declaración (default: "1.0.0")
```

El `id` es la identidad técnica del módulo. Aparece en logs, métricas, cabeceras de contexto y rutas internas. **Nunca debe coincidir con el nombre de un Engine.**

```yaml
# Correcto
module:
  id: keepme
  version: "1.0.0"

# Incorrecto — el id no puede ser el nombre de un Engine
module:
  id: inventory           # ❌
```

---

### 3.2 `metadata`

```yaml
metadata:
  display_name: string    # requerido — nombre comercial visible al usuario
  description:  string    # requerido — una línea: qué problema resuelve este módulo
  owner:        string    # equipo responsable (e.g. "platform", "product-keepme")
  status:       enum      # planned | active | deprecated | sunset
  tags:                   # etiquetas para búsqueda y agrupación
    - string
```

---

### 3.3 `blueprint`

```yaml
# Opción A — referencia a un Blueprint nombrado del catálogo
blueprint: INVENTORY_ONLY

# Opción B — composición inline (cuando no existe un Blueprint reutilizable)
# Se omite `blueprint` y se declara `engines` + `contracts`
```

Si se declara `blueprint`, los campos `engines` y `contracts` son opcionales y pueden omitirse (el Runtime los resuelve desde el catálogo). Si se declara la composición inline, `engines` y `contracts` son requeridos.

---

### 3.4 `engines`

```yaml
engines:
  - string    # identificador del Engine (e.g. "inventory", "crm", "service")
```

Lista ordenada de Engines que este módulo consume. El orden no afecta la ejecución — es solo declarativo.

---

### 3.5 `contracts`

```yaml
contracts:
  {engine_id}:
    version: string       # versión del Contract (e.g. "v1")
```

Por cada Engine declarado en `engines`, se especifica qué versión del Contract consume este módulo.

```yaml
contracts:
  inventory:
    version: v1
  service:
    version: v1
```

---

### 3.6 `capabilities`

```yaml
capabilities:
  {engine_id}:
    {capability_name}: boolean    # true = activa | false = inactiva (default)
```

Las Capabilities no declaradas se tratan como `false`. Solo las Capabilities con `true` se incluyen en el pipeline de ejecución.

El Business Runtime valida el grafo de `requires` al construir el pipeline: si se activa una Capability que requiere otra, la dependencia también debe estar en `true`. Un conflicto es un error de declaración — no se inicia el módulo.

```yaml
capabilities:
  inventory:
    asset_registry: true    # raíz — obligatoria si cualquier otra está activa
    assignment:     true
    transfer:       true
    inspection:     true
    maintenance:    false
    reservation:    false
    qr_barcode:     true
    rfid:           false
    kits:           true
    batch_ops:      false
    audit_trail:    true
    lifecycle:      false
    availability:   false
```

---

### 3.7 `workflows`

```yaml
workflows:
  {workflow_id}:
    description: string
    trigger:     string    # evento o acción que inicia el workflow
    steps:
      - capability: string
        action:    string
        on_success: string   # siguiente paso o "end"
        on_failure: string   # siguiente paso, "end" o "rollback"
```

Los workflows declaran flujos de negocio que el Runtime orquesta usando las Capabilities activas. Un workflow no puede invocar una Capability que no esté declarada como `true` en `capabilities`.

```yaml
workflows:
  asset_checkout:
    description: Registrar la salida de un activo del almacén.
    trigger: user.action.checkout
    steps:
      - capability: inspection
        action:    record_exit_inspection
        on_success: assign_step
        on_failure: end
      - id: assign_step
        capability: assignment
        action:    assign_to_project
        on_success: qr_step
        on_failure: end
      - id: qr_step
        capability: qr_barcode
        action:    print_exit_label
        on_success: end
        on_failure: end
```

---

### 3.8 `events`

```yaml
events:
  publishes:
    - string    # nombre del evento de dominio que este módulo emite
  consumes:
    - string    # nombre del evento de dominio que este módulo escucha
```

Los eventos en `publishes` deben existir en la definición de `publishes` de alguna Capability activa del módulo. Los eventos en `consumes` deben estar en la definición de `consumes` de alguna Capability activa, o bien el módulo debe manejarlos explícitamente en un workflow.

```yaml
events:
  publishes:
    - inventory.asset.assigned
    - inventory.asset.transferred
    - inventory.asset.inspection.completed
    - inventory.kit.assembled
  consumes:
    - crm.deal.won
    - project.completed
    - project.cancelled
```

---

### 3.9 `permissions`

```yaml
permissions:
  - string    # identificadores de permiso requeridos por el módulo
```

Lista de permisos que el Authorization Engine (Sprint 4) verificará antes de permitir acceso a las operaciones de este módulo. Los permisos siguen el formato `{ENGINE}_{OPERATION}`.

```yaml
permissions:
  - INVENTORY_READ
  - INVENTORY_ASSIGN
  - INVENTORY_TRANSFER
  - INVENTORY_INSPECT
  - INVENTORY_WRITE
```

---

### 3.10 `configuration`

```yaml
configuration:
  {key}: {value}    # parámetros específicos de este módulo
```

Parámetros de comportamiento que no son Capabilities pero que afectan cómo opera el módulo. El Runtime los pasa al Engine como contexto de ejecución.

```yaml
configuration:
  qr_label_format: "QR_CODE_128"
  max_assignment_days: 30
  allow_partial_kit_assignment: false
  inspection_required_on_exit: true
  inspection_required_on_return: true
  audit_retention_days: 365
```

---

### 3.11 `ui`

```yaml
ui:
  nav:
    label:  string    # texto en la navegación principal
    icon:   string    # identificador de icono del design system
    order:  integer   # posición en el menú
  routes:
    - path:   string  # ruta de la aplicación
      view:   string  # componente del frontend que renderiza esta ruta
      access: string  # permiso requerido para acceder
```

```yaml
ui:
  nav:
    label: "KeepMe"
    icon:  "package"
    order: 1
  routes:
    - path:   /keepme/assets
      view:   AssetList
      access: INVENTORY_READ
    - path:   /keepme/assets/:id
      view:   AssetDetail
      access: INVENTORY_READ
    - path:   /keepme/assignments
      view:   AssignmentList
      access: INVENTORY_ASSIGN
    - path:   /keepme/checkout
      view:   CheckoutFlow
      access: INVENTORY_ASSIGN
```

---

## 4. Ejemplos completos

### KeepMe — Renta de Equipo (single-engine)

```yaml
module:
  id: keepme
  version: "1.0.0"

metadata:
  display_name: "KeepMe"
  description:  "Gestión del ciclo de vida de activos de renta — salida, seguimiento y retorno."
  owner:        "product-keepme"
  status:       planned
  tags:
    - inventory
    - rental
    - assets

blueprint: INVENTORY_ONLY

contracts:
  inventory:
    version: v1

capabilities:
  inventory:
    asset_registry: true
    assignment:     true
    transfer:       true
    inspection:     true
    maintenance:    false
    reservation:    false
    qr_barcode:     true
    rfid:           false
    kits:           true
    batch_ops:      false
    audit_trail:    true
    lifecycle:      false
    availability:   false

workflows:
  asset_checkout:
    description: Salida de un activo del almacén hacia un proyecto.
    trigger: user.action.checkout
    steps:
      - capability: inspection
        action:    record_exit_inspection
        on_success: assign_step
        on_failure: end
      - id: assign_step
        capability: assignment
        action:    assign_to_project
        on_success: label_step
        on_failure: end
      - id: label_step
        capability: qr_barcode
        action:    print_exit_label
        on_success: end
        on_failure: end

  asset_return:
    description: Retorno de un activo al almacén desde un proyecto.
    trigger: user.action.return
    steps:
      - capability: inspection
        action:    record_return_inspection
        on_success: unassign_step
        on_failure: end
      - id: unassign_step
        capability: assignment
        action:    unassign_from_project
        on_success: end
        on_failure: end

events:
  publishes:
    - inventory.asset.assigned
    - inventory.asset.unassigned
    - inventory.asset.transferred
    - inventory.asset.inspection.completed
    - inventory.kit.assembled
    - inventory.kit.disassembled
  consumes:
    - crm.deal.won
    - project.completed
    - project.cancelled

permissions:
  - INVENTORY_READ
  - INVENTORY_ASSIGN
  - INVENTORY_TRANSFER
  - INVENTORY_INSPECT
  - INVENTORY_WRITE

configuration:
  qr_label_format:            "QR_CODE_128"
  max_assignment_days:        30
  allow_partial_kit_checkout: true
  inspection_required_on_exit:    true
  inspection_required_on_return:  true
  audit_retention_days:       365

ui:
  nav:
    label: "KeepMe"
    icon:  "package"
    order: 1
  routes:
    - path:   /keepme/assets
      view:   AssetList
      access: INVENTORY_READ
    - path:   /keepme/assets/:id
      view:   AssetDetail
      access: INVENTORY_READ
    - path:   /keepme/kits
      view:   KitList
      access: INVENTORY_READ
    - path:   /keepme/assignments
      view:   AssignmentList
      access: INVENTORY_ASSIGN
    - path:   /keepme/checkout
      view:   CheckoutFlow
      access: INVENTORY_ASSIGN
    - path:   /keepme/return
      view:   ReturnFlow
      access: INVENTORY_ASSIGN
```

---

### Celebrate — Eventos Especiales (multi-engine)

```yaml
module:
  id: celebrate
  version: "1.0.0"

metadata:
  display_name: "Celebrate"
  description:  "Logística de activos para eventos especiales — reserva, despacho y retorno."
  owner:        "product-celebrate"
  status:       planned
  tags:
    - inventory
    - crm
    - events

engines:
  - inventory
  - crm

contracts:
  inventory:
    version: v1
  crm:
    version: v1

capabilities:
  inventory:
    asset_registry:  true
    assignment:      false
    transfer:        true
    inspection:      false
    maintenance:     false
    reservation:     true
    qr_barcode:      false
    rfid:            false
    kits:            false
    batch_ops:       false
    audit_trail:     false
    lifecycle:       false
    availability:    true
  crm:
    contact_management: true
    pipeline:           true
    deal_tracking:      true
    activity_log:       false
    email_integration:  false

events:
  publishes:
    - inventory.asset.reserved
    - inventory.asset.reservation.released
    - inventory.asset.transferred
    - inventory.availability.updated
  consumes:
    - crm.deal.won
    - crm.deal.lost
    - project.completed
    - project.cancelled

permissions:
  - INVENTORY_READ
  - INVENTORY_RESERVE
  - INVENTORY_TRANSFER
  - CRM_READ

configuration:
  min_reservation_advance_days: 3
  auto_release_on_deal_lost:    true
  availability_calendar_view:   "week"

ui:
  nav:
    label: "Celebrate"
    icon:  "star"
    order: 2
  routes:
    - path:   /celebrate/catalog
      view:   AvailabilityCatalog
      access: INVENTORY_READ
    - path:   /celebrate/reservations
      view:   ReservationList
      access: INVENTORY_RESERVE
    - path:   /celebrate/calendar
      view:   AvailabilityCalendar
      access: INVENTORY_READ
```

---

### Marketing Operations — Composición compleja (CRM + Creative + Project)

```yaml
module:
  id: marketing_ops
  version: "1.0.0"

metadata:
  display_name: "Marketing Operations"
  description:  "Gestión de campañas — pipeline comercial, producción creativa y planificación."
  owner:        "product-marketing"
  status:       planned
  tags:
    - crm
    - creative
    - project

blueprint: CAMPAIGN_BLUEPRINT

contracts:
  crm:
    version: v1
  creative:
    version: v1
  project:
    version: v1

capabilities:
  crm:
    contact_management: true
    pipeline:           true
    deal_tracking:      true
    activity_log:       true
    email_integration:  true
  creative:
    brief_management:    true
    deliverable_tracking: true
    approval_workflow:   true
    feedback_threads:    true
  project:
    planning:            true
    milestone_tracking:  true
    team_assignment:     true

events:
  publishes:
    - crm.deal.won
    - creative.deliverable.approved
    - creative.approval.completed
  consumes:
    - crm.deal.stage.changed
    - creative.deliverable.submitted

permissions:
  - CRM_READ
  - CRM_WRITE
  - CREATIVE_READ
  - CREATIVE_WRITE
  - CREATIVE_APPROVE
  - PROJECT_READ

configuration:
  approval_stages:           2
  auto_brief_on_deal_won:    true
  deliverable_reminder_days: 3

ui:
  nav:
    label: "Marketing"
    icon:  "megaphone"
    order: 5
  routes:
    - path: /marketing/campaigns
      view: CampaignList
      access: CRM_READ
    - path: /marketing/campaigns/:id
      view: CampaignDetail
      access: CRM_READ
    - path: /marketing/briefs
      view: BriefList
      access: CREATIVE_READ
    - path: /marketing/deliverables
      view: DeliverableList
      access: CREATIVE_READ
```

---

## 5. Reglas de validación

El Business Runtime valida toda declaración antes de construir el pipeline. Un error de validación impide el inicio del módulo.

### 5.1 Validación estructural

| Regla | Error |
|-------|-------|
| `module.id` es único en la plataforma | `DUPLICATE_MODULE_ID` |
| Todos los Engines en `engines` existen en el BUSINESS_ENGINES_CATALOG | `UNKNOWN_ENGINE` |
| Todas las Capabilities en `capabilities` existen en el Engine declarado | `UNKNOWN_CAPABILITY` |
| Todos los Contracts en `contracts` tienen versión publicada | `UNKNOWN_CONTRACT_VERSION` |
| Si se usa `blueprint`, existe en el catálogo | `UNKNOWN_BLUEPRINT` |

### 5.2 Validación de dependencias de Capabilities

```
Para cada Capability C con valor true:
  Para cada R en C.requires:
    capabilities[engine][R] debe ser true
    Si no → error CAPABILITY_REQUIRES_MISSING(C, R)
```

Ejemplo: si `reservation: true` y `availability: false` → `CAPABILITY_REQUIRES_MISSING(RESERVATION, AVAILABILITY_CALENDAR)`.

### 5.3 Validación de eventos

| Regla | Error |
|-------|-------|
| Cada evento en `events.publishes` debe existir en `publishes` de alguna Capability activa | `EVENT_NOT_PRODUCIBLE` |
| Cada evento en `events.consumes` debe existir en `consumes` de alguna Capability activa, o estar manejado en un workflow | `EVENT_NOT_CONSUMABLE` |

### 5.4 Validación de workflows

| Regla | Error |
|-------|-------|
| Cada `capability` referenciada en un `step` debe estar activa (`true`) | `WORKFLOW_USES_INACTIVE_CAPABILITY` |
| El `trigger` de un workflow debe ser un evento en `events.consumes` o una acción de usuario válida | `WORKFLOW_UNKNOWN_TRIGGER` |

---

## 6. Procesamiento por el Business Runtime

```
[1] LOAD          Lee el archivo .yaml del módulo
[2] PARSE         Valida la estructura (keys requeridas, tipos)
[3] RESOLVE       Si hay `blueprint`, carga su definición del catálogo
[4] VALIDATE      Ejecuta todas las reglas de §5
[5] BUILD         Construye el pipeline con las Capabilities activas
[6] REGISTER      Registra el módulo en el Runtime Registry
[7] READY         El módulo acepta peticiones
```

Si cualquier paso falla, el módulo no se inicia y el error se reporta con el código específico. Los pasos 1–4 ocurren en startup; los pasos 5–7 son hot-reloadable si el Runtime soporta recarga en caliente.

---

## 7. Versionado de Blueprints

**Los Blueprints son inmutables.**

Una vez publicado, `KEEPME_BLUEPRINT v1` no cambia nunca. Si el Blueprint necesita evolucionar, se publica `KEEPME_BLUEPRINT v2`. Los módulos apuntan explícitamente a una versión del Blueprint.

```yaml
# Módulo apuntando a una versión explícita del Blueprint
module:
  id: keepme
  version: "2.0.0"

blueprint: INVENTORY_ONLY@v2    # versión explícita — nunca "latest"
```

Esta política garantiza:

| Propiedad | Descripción |
|-----------|-------------|
| **Reproducibilidad** | Dos deployments del mismo módulo con la misma Blueprint version producen exactamente el mismo pipeline |
| **Auditoría** | Siempre se puede saber qué Blueprint estaba activo en un momento dado |
| **Rollback** | Revertir un módulo a una versión anterior del Blueprint es una operación declarativa |
| **Migraciones controladas** | La transición de v1 a v2 es explícita y planificada — no silenciosa |

**Ciclo de vida de una versión de Blueprint:**

```
draft       — en definición, no disponible para módulos
published   — estable, disponible para uso en producción
deprecated  — sigue funcionando, pero los módulos deben migrar a la siguiente versión
sunset      — retirada, ya no se acepta en nuevos deployments (plazo anunciado con anticipación)
```

**Política de deprecación:**

- Una versión no se retira sin al menos 2 sprints de aviso.
- Durante ese período, el Runtime registra warnings para módulos usando la versión deprecated.
- El Runtime nunca detiene silenciosamente un módulo en `deprecated` — solo en `sunset` con fecha explícita.

**Convención de nombres:**

```
{BLUEPRINT_ID}@v{N}

Ejemplos:
  INVENTORY_ONLY@v1
  CAMPAIGN_BLUEPRINT@v1
  OPERATIONAL_BLUEPRINT@v2
```

La `N` es un entero mayor. No hay semver en los Blueprints — la versión es una ruptura de contrato, no un patch.

---

## 8. Gobernanza

| Acción | Quién puede ejecutarla | Proceso |
|--------|----------------------|---------|
| Crear un nuevo módulo | Equipo de producto | PR con nueva declaración + revisión de arquitectura |
| Modificar `capabilities` de un módulo activo | Equipo de producto | PR + revisión + deploy |
| Añadir un Engine a un módulo existente | Equipo de producto + plataforma | PR + ADR si es cambio de Blueprint |
| Modificar `workflows` | Equipo de producto | PR + revisión |
| Publicar un nuevo Blueprint | Equipo de plataforma | Actualizar BUSINESS_ENGINES_CATALOG.md + ADR |
| Publicar una nueva versión de Blueprint (`v2`) | Equipo de plataforma | ADR + plan de migración para módulos en `v1` |
| Deprecar una versión de Blueprint | Arquitectura | Anuncio con ≥ 2 sprints de anticipación |
| Deprecar un módulo | Arquitectura | ADR + plan de migración |

**Regla de oro:** una declaración de módulo no requiere cambios en el código del Engine. Si el cambio que necesitas en el módulo implica modificar un Engine, ese requerimiento pertenece al equipo de plataforma y requiere un ADR.

---

*Especificación oficial del lenguaje de declaración de módulos de Quantum. Versión 1.1 — 2026-08-04.*
