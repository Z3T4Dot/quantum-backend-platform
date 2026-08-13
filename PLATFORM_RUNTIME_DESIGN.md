# Quantum Platform — Runtime Technical Design

**Versión:** 1.0  
**Fecha:** 2026-08-04  
**Estado:** Diseño técnico (Sprint 6 — entregable formal)  
**Clasificación:** Referencia técnica interna — Brandex Global

---

## Índice

1. [El objetivo](#1-el-objetivo)
2. [Visión general de Platform.start()](#2-visión-general-de-platformstart)
3. [Los ocho componentes del Runtime](#3-los-ocho-componentes-del-runtime)
   - [Module Registry](#31-module-registry)
   - [Engine Registry](#32-engine-registry)
   - [Contract Registry](#33-contract-registry)
   - [Capability Registry](#34-capability-registry)
   - [Blueprint Compiler](#35-blueprint-compiler)
   - [Runtime Loader](#36-runtime-loader)
   - [Module Installer](#37-module-installer)
   - [Engine Dispatcher](#38-engine-dispatcher)
4. [Secuencia de arranque](#4-secuencia-de-arranque)
5. [Engine Dispatcher — Routing](#5-engine-dispatcher--routing)
6. [Module Installer — Registration Flow](#6-module-installer--registration-flow)
7. [Interacción entre componentes](#7-interacción-entre-componentes)
8. [Invariantes del Runtime](#8-invariantes-del-runtime)

---

## 1. El objetivo

Un equipo de producto escribe un archivo:

```yaml
module:
  id: keepme
  name: KeepMe

blueprint: inventory-v1

engines:
  - inventory

capabilities:
  - asset_registry
  - assignment
  - inspection
  - kits
```

Luego ejecuta `Platform.start()`.

Sin escribir una sola línea de código específica para KeepMe, el sistema produce:

```
Loading Blueprint...
  ✓ Inventory Contract v1

Resolving Capabilities...
  ✓ Asset Registry
  ✓ Assignment
  ✓ Inspection
  ✓ Kits

Compiling RuntimeContext...
  ✓ Runtime Ready

Registering Module...
  ✓ KeepMe Registered

Publishing Navigation...
  ✓ Sidebar Updated

Publishing Routes...
  ✓ /keepme

Publishing Permissions...
  ✓ Inventory Permissions

Publishing Menus...
  ✓ Inventory Module

Done.
```

KeepMe existe. Sin un `keepme-service`. Sin un `KeepMeController`. Sin un `KeepMeRepository`.

Eso es exactamente lo que diferencia a Quantum de un ERP tradicional.

El componente que produce ese resultado se llama **Platform Runtime**. Este documento describe su diseño técnico.

---

## 2. Visión general de Platform.start()

```
                     keepme.yml
                         │
                         ↓
              ┌─────────────────────┐
              │   Blueprint Compiler │  Lee el YAML, valida schema,
              │                     │  resuelve Capabilities,
              │                     │  compila RuntimeContext
              └─────────┬───────────┘
                        │ RuntimeContext (inmutable)
                        ↓
              ┌─────────────────────┐
              │    Runtime Loader   │  Recibe el RuntimeContext
              │                     │  y orquesta el arranque
              └──┬────────┬─────────┘
                 │        │
       ┌─────────┘        └──────────┐
       ↓                             ↓
┌─────────────┐             ┌────────────────┐
│  Module     │             │  Module        │
│  Registry   │             │  Installer     │
│             │             │                │
│ register()  │             │ routes         │
│ find()      │             │ menu           │
│ list()      │             │ permissions    │
└─────────────┘             │ workflows      │
                            │ events         │
                            │ navigation     │
                            └────────────────┘

                 Petición en producción:
                 POST /keepme/assets
                         │
                         ↓
              ┌─────────────────────┐
              │  Engine Dispatcher  │  Sabe: KeepMe → Inventory → ASSET_REGISTRY
              └─────────┬───────────┘
                        │ BusinessContext (sin ModuleName)
                        ↓
              ┌─────────────────────┐
              │  Inventory Engine   │  No sabe que es KeepMe.
              │  (ASSET_REGISTRY)   │  Solo ejecuta la Capability.
              └─────────────────────┘
```

---

## 3. Los ocho componentes del Runtime

### 3.1 Module Registry

**Responsabilidad:** saber qué módulos están registrados en la plataforma en un momento dado.

```
ModuleRegistry {
  register(module: ModuleDescriptor): void
  unregister(moduleId: String): void
  find(moduleId: String): Optional<ModuleDescriptor>
  list(): List<ModuleDescriptor>
  exists(moduleId: String): boolean
}

ModuleDescriptor {
  id:           String              // "keepme"
  name:         String              // "KeepMe"
  blueprintId:  String              // "inventory-v1"
  runtimeContext: RuntimeContext    // compilado por Blueprint Compiler
  status:       ModuleStatus        // LOADING | ACTIVE | FAILED | UNREGISTERED
  registeredAt: Instant
}
```

El Module Registry no valida ni compila — solo almacena y sirve. La validación ocurre en el Blueprint Compiler antes de que el módulo llegue al Registry.

### 3.2 Engine Registry

**Responsabilidad:** saber qué Engines están disponibles en la plataforma y cómo invocarlos.

```
EngineRegistry {
  register(engine: EngineDescriptor): void
  find(engineId: String): Optional<EngineDescriptor>
  list(): List<EngineDescriptor>
}

EngineDescriptor {
  id:           String              // "inventory"
  version:      String              // "1.0"
  capabilities: List<String>        // Capabilities que este Engine puede ejecutar
  contractId:   String              // "inventory-v1"
  handler:      EngineHandler       // referencia al handler real del Engine
}
```

Los Engines se registran en el Engine Registry al arrancar la plataforma — antes de que ningún módulo sea instalado. Cuando un Blueprint Compiler necesita resolver un Engine, consulta el Engine Registry.

### 3.3 Contract Registry

**Responsabilidad:** saber qué contratos existen y qué versión de cada Engine exponen.

```
ContractRegistry {
  register(contract: ContractDescriptor): void
  find(contractId: String): Optional<ContractDescriptor>
  findByEngine(engineId: String, version: String): Optional<ContractDescriptor>
}

ContractDescriptor {
  id:           String              // "inventory-v1"
  engineId:     String              // "inventory"
  version:      String              // "v1"
  capabilities: List<String>        // Capabilities que expone este contrato
  publishedAt:  Instant
  status:       ContractStatus      // ACTIVE | DEPRECATED | SUNSET
}
```

El Contract Registry garantiza que cuando un Blueprint declara `blueprint: inventory-v1`, ese contrato existe, está activo y expone exactamente las Capabilities que el Blueprint necesita.

### 3.4 Capability Registry

**Responsabilidad:** almacenar los `CapabilityDescriptor` de todos los Engines. Es la fuente de verdad sobre qué hace cada Capability y qué depende de qué.

```
CapabilityRegistry {
  register(capability: CapabilityDescriptor): void
  find(capabilityId: String): Optional<CapabilityDescriptor>
  resolveDependencies(capabilityId: String): List<CapabilityDescriptor>
  validateGraph(capabilities: List<String>): ValidationResult
}

CapabilityDescriptor {
  id:                  String              // "ASSET_REGISTRY"
  version:             Int                 // 1
  engineId:            String              // "inventory"
  dependencies:        List<String>        // otras Capabilities requeridas
  permissions:         List<String>        // permisos que activa
  events: {
    publishes:         List<String>        // eventos que esta Capability produce
    consumes:          List<String>        // eventos que esta Capability necesita
  }
  configurationSchema: JsonSchema          // validación de valores de configuración
}
```

El Capability Registry no ejecuta nada. Solo describe. La ejecución ocurre en el Engine, mediada por el Engine Dispatcher.

### 3.5 Blueprint Compiler

**Responsabilidad:** leer un archivo `.yml` de Blueprint y producir un `RuntimeContext` válido e inmutable. Es el componente más complejo del Runtime.

```
BlueprintCompiler {
  compile(blueprintFile: BlueprintFile): CompilationResult
}

CompilationResult {
  success:        boolean
  runtimeContext: RuntimeContext    // presente si success=true
  errors:         List<CompilationError>  // presente si success=false
}
```

**Pipeline de compilación (en orden estricto):**

```
1. Schema Validator
   └─ Lee el YAML — verifica que todos los campos requeridos existen y tienen el tipo correcto
   └─ Error: INVALID_SCHEMA

2. Blueprint Resolver
   └─ Busca en Contract Registry el blueprint declarado ("inventory-v1")
   └─ Error: BLUEPRINT_NOT_FOUND, BLUEPRINT_DEPRECATED, BLUEPRINT_SUNSET

3. Engine Resolver
   └─ Para cada Engine declarado, busca en Engine Registry
   └─ Error: ENGINE_NOT_FOUND, ENGINE_VERSION_MISMATCH

4. Capability Resolver
   └─ Para cada Capability declarada, busca en Capability Registry
   └─ Error: CAPABILITY_NOT_FOUND, CAPABILITY_NOT_IN_CONTRACT

5. Dependency Validator
   └─ Ejecuta el grafo de `requires` — si INSPECTION está activo, ASSET_REGISTRY debe estarlo
   └─ Detecta dependencias transitivas no satisfechas
   └─ Detecta ciclos en el grafo
   └─ Error: CAPABILITY_REQUIRES_MISSING, CIRCULAR_DEPENDENCY

6. Event Validator
   └─ Para cada evento consumido, verifica que algún Engine del Blueprint lo publica
   └─ Error: EVENT_NOT_PRODUCIBLE

7. Configuration Validator
   └─ Valida los valores de configuración contra el configurationSchema de cada Capability activa
   └─ Error: CONFIGURATION_INVALID

8. RuntimeContext Builder
   └─ Compila el RuntimeContext inmutable con todas las piezas validadas
   └─ Sin errores posibles en este paso — todo está validado
```

Si cualquier paso falla, el Compiler devuelve `CompilationResult { success: false, errors: [...] }`. El módulo nunca llega al Runtime Loader.

### 3.6 Runtime Loader

**Responsabilidad:** recibir un `RuntimeContext` ya compilado y orquestar su activación — en el orden correcto.

```
RuntimeLoader {
  load(runtimeContext: RuntimeContext): LoadResult
  unload(moduleId: String): void
}
```

**Secuencia de carga:**

```
1. Verificar que el moduleId no está ya registrado (idempotencia)
2. Notificar a cada Engine involucrado que va a inicializarse un nuevo contexto
3. Construir el BusinessContext para cada Engine (sin ModuleName)
4. Pasar cada BusinessContext al Engine correspondiente
5. Si todos los Engines inicializan exitosamente → registrar en Module Registry
6. Delegar al Module Installer para registrar rutas, menú, permisos, eventos, navegación
7. Emitir evento: platform.module.registered (lo escucha el frontend, Prometheus, logs)
```

Si algún Engine falla en la inicialización, el Runtime Loader hace rollback de los Engines que ya inicializaron — el módulo no queda en estado parcial.

### 3.7 Module Installer

**Responsabilidad:** tomar el `RuntimeContext` de un módulo activo y publicar todo lo que el resto de la plataforma necesita saber sobre él. Es quien produce el output visible de `Platform.start()`.

```
ModuleInstaller {
  install(runtimeContext: RuntimeContext): InstallResult
  uninstall(moduleId: String): void
}
```

**Registros que el Module Installer publica automáticamente:**

| Registro | Qué publica | Fuente en el RuntimeContext |
|----------|-------------|---------------------------|
| **Rutas** | `/keepme`, `/keepme/assets`, `/keepme/assignments`, ... | `ui.routes` del Blueprint |
| **Navegación** | Entrada en sidebar con label, ícono y orden | `ui.nav` del Blueprint |
| **Permisos** | `INVENTORY_READ`, `INVENTORY_ASSIGN`, ... | `permissions` del Blueprint |
| **Menús** | Submenús internos del módulo | `ui.routes` + capabilities activas |
| **Workflows** | `asset_checkout`, `asset_return`, ... | `workflows` del Blueprint |
| **Eventos** | Qué eventos publica y consume este módulo | `events` del Blueprint |
| **Metadata** | id, nombre, descripción, tags, owner | `metadata` del Blueprint |

El Module Installer no toma decisiones de negocio. Todo lo que registra viene del `RuntimeContext` — que a su vez viene del Blueprint declarado.

### 3.8 Engine Dispatcher

**Responsabilidad:** cuando llega una petición dirigida a un módulo, saber exactamente qué Engine y qué Capability deben procesarla — sin que el Engine sepa nada del módulo.

```
EngineDispatcher {
  dispatch(request: ModuleRequest): EngineResponse
}

ModuleRequest {
  moduleId:      String    // "keepme"
  capabilityId:  String    // "ASSET_REGISTRY"
  operation:     String    // "createAsset"
  payload:       Object
  correlationId: String
}
```

**Routing logic:**

```
POST /keepme/assets
        │
        ↓
EngineDispatcher.dispatch(
  moduleId: "keepme",
  capabilityId: "ASSET_REGISTRY",
  operation: "createAsset"
)
        │
        ↓
1. Consulta Module Registry → RuntimeContext de KeepMe
2. Verifica que ASSET_REGISTRY está activo para KeepMe
3. Consulta Engine Registry → Inventory Engine
4. Construye BusinessContext {
     tenantId:      "brandex",
     capabilities:  ["ASSET_REGISTRY", "ASSIGNMENT", "INSPECTION", "KITS"],
     permissions:   ["INVENTORY_READ", "INVENTORY_WRITE", "INVENTORY_ASSIGN"],
     configuration: { qr_label_format: "QR_CODE_128", max_assignment_days: 30, ... },
     correlationId: "abc-123"
   }
        │
        ↓
Inventory Engine.handle(capability: "ASSET_REGISTRY", operation: "createAsset", context: BusinessContext)
        │
        ↓ El Engine no sabe que fue KeepMe quien llamó.
          Solo sabe que debe ejecutar createAsset con ese BusinessContext.
```

**Garantía del Dispatcher:** si una petición intenta invocar una Capability que no está activa para ese módulo (por ejemplo, `MAINTENANCE` en KeepMe que no lo declara), el Dispatcher devuelve `CAPABILITY_NOT_DECLARED` antes de llegar al Engine.

---

## 4. Secuencia de arranque

```
Platform.start()
     │
     ├─► Engine Registry.register(InventoryEngine)     ← Engines primero
     ├─► Engine Registry.register(CRMEngine)
     ├─► Engine Registry.register(CreativeEngine)
     │
     ├─► Contract Registry.register(inventory-v1)      ← Contratos segundo
     ├─► Contract Registry.register(crm-v1)
     ├─► Contract Registry.register(creative-v1)
     │
     ├─► Capability Registry.register(ASSET_REGISTRY)  ← Capabilities tercero
     ├─► Capability Registry.register(ASSIGNMENT)
     ├─► Capability Registry.register(INSPECTION)
     ├─► ... (todas las Capabilities de todos los Engines)
     │
     ├─► BlueprintCompiler.compile(keepme.yml)          ← Módulos último
     │       │
     │       ├─ Schema Validator     ✓
     │       ├─ Blueprint Resolver   ✓ inventory-v1
     │       ├─ Engine Resolver      ✓ inventory
     │       ├─ Capability Resolver  ✓ ASSET_REGISTRY, ASSIGNMENT, INSPECTION, KITS
     │       ├─ Dependency Validator ✓ grafo satisfecho
     │       ├─ Event Validator      ✓
     │       ├─ Config Validator     ✓
     │       └─ RuntimeContext.build() → RuntimeContext (inmutable)
     │
     ├─► RuntimeLoader.load(runtimeContext)
     │       │
     │       ├─ Inventory Engine.init(BusinessContext)  ✓
     │       └─ Module Registry.register(ModuleDescriptor)
     │
     └─► ModuleInstaller.install(runtimeContext)
             │
             ├─ Routes:      /keepme, /keepme/assets, ...
             ├─ Navigation:  KeepMe en sidebar
             ├─ Permissions: INVENTORY_*
             ├─ Menus:       Activos, Asignaciones, ...
             ├─ Workflows:   asset_checkout, asset_return
             └─ Events:      publish/consume registrados

LOG: KeepMe Registered ✓
```

**Orden de arranque es obligatorio:**

```
Engines → Contracts → Capabilities → Blueprints → Módulos
```

Un Blueprint que intente compilarse antes de que los Engines estén registrados fallará en el Engine Resolver. Esto es intencional — los Engines son la infraestructura, los Blueprints son las configuraciones. La infraestructura siempre primero.

---

## 5. Engine Dispatcher — Routing

El Engine Dispatcher mantiene internamente una tabla de routing que se construye durante `ModuleInstaller.install()`:

```
Routing Table (ejemplo con KeepMe activo):

moduleId  | capabilityId      | engineId   | contractId
----------|-------------------|------------|------------
keepme    | ASSET_REGISTRY    | inventory  | inventory-v1
keepme    | ASSIGNMENT        | inventory  | inventory-v1
keepme    | INSPECTION        | inventory  | inventory-v1
keepme    | KITS              | inventory  | inventory-v1
```

Cuando llega una petición:

```
1. Lookup: moduleId + capabilityId → (engineId, contractId)
2. Si no existe → CAPABILITY_NOT_DECLARED (400 - Bad Request)
3. Lookup: engineId → EngineHandler en Engine Registry
4. Build BusinessContext desde RuntimeContext del módulo
5. Invoke: EngineHandler.handle(capability, operation, BusinessContext)
6. Return response
```

**Lo que el Dispatcher no hace:**
- No transforma el request de negocio (eso es responsabilidad del Engine)
- No interpreta el resultado (el Engine devuelve la respuesta, el Dispatcher la propaga)
- No mantiene estado de sesión (el BusinessContext contiene lo que el Engine necesita)
- No conoce qué significa `createAsset` — eso lo sabe el Engine

---

## 6. Module Installer — Registration Flow

La instalación de un módulo produce exactamente cuatro tipos de artefactos que el resto de la plataforma consume:

**Artefactos de API:**
```
Rutas HTTP registradas dinámicamente:
  GET    /keepme
  GET    /keepme/assets
  POST   /keepme/assets
  GET    /keepme/assets/{id}
  PUT    /keepme/assets/{id}
  DELETE /keepme/assets/{id}
  GET    /keepme/assignments
  POST   /keepme/assignments
  ...

Origen: capabilities activas → sus operaciones CRUD estándar + operaciones específicas del Blueprint
```

**Artefactos de UI (consumidos por el frontend):**
```json
{
  "moduleId": "keepme",
  "nav": {
    "label": "KeepMe",
    "icon": "package",
    "order": 1,
    "path": "/keepme"
  },
  "routes": [
    { "path": "/keepme/assets",      "view": "AssetList",       "access": "INVENTORY_READ"   },
    { "path": "/keepme/assets/:id",  "view": "AssetDetail",     "access": "INVENTORY_READ"   },
    { "path": "/keepme/assignments", "view": "AssignmentList",  "access": "INVENTORY_ASSIGN" }
  ]
}
```

**Artefactos de seguridad (consumidos por identity-service):**
```
Permisos registrados para este módulo:
  INVENTORY_READ
  INVENTORY_WRITE
  INVENTORY_ASSIGN
  INVENTORY_TRANSFER
  INVENTORY_INSPECT
```

**Artefactos de eventos (consumidos por el Bus de eventos):**
```
Publica:  inventory.asset.created
          inventory.asset.assigned
          inventory.inspection.recorded
          inventory.kit.assembled

Consume:  crm.deal.won
          project.completed
          project.cancelled
```

Estos cuatro artefactos se generan automáticamente desde el `RuntimeContext`. No existe código específico de KeepMe que los produzca.

---

## 7. Interacción entre componentes

```
                 ┌───────────────────────────────┐
                 │         Platform Boot          │
                 └───────────────┬───────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          ↓                      ↓                      ↓
  Engine Registry        Contract Registry      Capability Registry
  (Engines first)        (Contracts second)     (Capabilities third)
          │                      │                      │
          └──────────────────────┴──────────────────────┘
                                 │
                                 ↓ (todo registrado)
                        Blueprint Compiler
                        (lee keepme.yml)
                                 │
                         RuntimeContext
                                 │
                        Runtime Loader
                        /               \
               Module Registry     Module Installer
               (guarda el módulo)   (publica artefactos)
                                         │
                                   Engine Dispatcher
                                   (tabla de routing)

         ─────── En producción ───────

         POST /keepme/assets
                  │
         Engine Dispatcher
                  │ (lookup: keepme + ASSET_REGISTRY → inventory)
         Inventory Engine.handle(BusinessContext)
                  │
            Asset creado ✓
```

---

## 8. Invariantes del Runtime

Estas condiciones son verificadas automáticamente por la Architecture Validation Suite (Sprint 8):

| Invariante | Verificación |
|-----------|--------------|
| Un módulo nunca llega al Module Registry sin haber pasado por el Blueprint Compiler | Todo `ModuleDescriptor` en el Registry tiene un `RuntimeContext` compilado y validado |
| El Engine Dispatcher nunca enruta a una Capability no activa para el módulo | Toda petición pasa por el lookup en la Routing Table |
| El `BusinessContext` nunca contiene `ModuleName` | El objeto `BusinessContext` no tiene campo `moduleName` — no puede existir |
| El `RuntimeContext` es inmutable desde el momento en que el Blueprint Compiler lo produce | No existen setters en `RuntimeContext` |
| El orden de arranque Engines → Contracts → Capabilities → Módulos nunca se invierte | El Runtime Loader rechaza `compile()` si los Registries no están inicializados |
| Un mismo Blueprint compilado dos veces produce el mismo `RuntimeContext` | Determinismo: dado el mismo input, el Blueprint Compiler produce el mismo output |
| La desinstalación de un módulo limpia todos sus artefactos de las cuatro categorías | `ModuleInstaller.uninstall()` es la operación inversa exacta de `install()` |

---

## 9. Engine Manifest — Auto-registro del Engine

Cada Business Engine se autodescribe mediante un archivo `{engine}-engine.yml` que el Runtime lee al arrancar. Este archivo es la fuente de verdad que el Engine Registry usa para registrar el Engine, sus Contracts y sus Capabilities — sin que nadie lo haga manualmente.

**Ejemplo — `inventory-engine.yml`:**

```yaml
engine:
  id: inventory
  version: "1.0"
  name: "Inventory Engine"
  description: "Gestión del ciclo de vida completo de activos físicos"

contract:
  id: inventory-v1
  version: v1

capabilities:
  - id: asset_registry
    version: 1
    dependencies: []
    permissions:
      - INVENTORY_READ
      - INVENTORY_WRITE
    events:
      publishes:
        - inventory.asset.registered
        - inventory.asset.updated
        - inventory.asset.deactivated
      consumes: []

  - id: assignment
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_ASSIGN
    events:
      publishes:
        - inventory.asset.assigned
        - inventory.asset.released
      consumes:
        - project.completed
        - project.cancelled

  - id: transfer
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_TRANSFER
    events:
      publishes:
        - inventory.asset.transferred
      consumes: []

  - id: inspection
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_INSPECT
    events:
      publishes:
        - inventory.inspection.recorded
      consumes: []

  - id: reservation
    version: 1
    dependencies:
      - asset_registry
      - availability_calendar
    permissions:
      - INVENTORY_RESERVE
    events:
      publishes:
        - inventory.asset.reserved
        - inventory.reservation.cancelled
      consumes:
        - crm.deal.won

  - id: kits
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_WRITE
    events:
      publishes:
        - inventory.kit.assembled
        - inventory.kit.disassembled
      consumes: []

  - id: lifecycle
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_WRITE
    events:
      publishes:
        - inventory.asset.activated
        - inventory.asset.decommissioned
      consumes: []

  - id: barcode
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_READ
    events:
      publishes:
        - inventory.barcode.scanned
      consumes: []

  - id: rfid
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_READ
    events:
      publishes:
        - inventory.rfid.detected
      consumes: []

  - id: audit
    version: 1
    dependencies:
      - asset_registry
    permissions:
      - INVENTORY_READ
    events:
      publishes: []
      consumes:
        - inventory.asset.registered
        - inventory.asset.assigned
        - inventory.asset.transferred
        - inventory.inspection.recorded
```

**Consecuencia:** cuando el Runtime arranca, lee este archivo y ejecuta automáticamente:

```
Engine Registry     → register(Inventory)
Contract Registry   → register(inventory-v1)
Capability Registry → register(ASSET_REGISTRY)
                   → register(ASSIGNMENT)
                   → register(TRANSFER)
                   → ... (10 capabilities)
```

Sin escribir una sola línea específica para Inventory en el Runtime.

**Invariante del Engine Manifest:** si una Capability está declarada en `inventory-engine.yml`, debe tener una implementación en `capabilities/{id}/` dentro del servicio. La Architecture Validation Suite (Sprint 8) verifica esta correspondencia automáticamente.

---

*Versión 1.1 — 2026-08-04. Este documento es el entregable principal de Sprint 6 (Runtime Technical Design). Sprint 7 implementa un subconjunto mínimo de estos componentes capaz de producir el log `KeepMe Registered ✓` dado un `keepme.yml` real.*
