# Quantum ERP — Platform Standards

**Versión:** 1.1  
**Fecha:** 2026-08-03  
**Estado:** Documento oficial de ingeniería  
**Relación:** Complementa `ARCHITECTURE_BLUEPRINT.md` — aplica sus decisiones en reglas concretas

---

## Propósito

El Architecture Blueprint define la arquitectura del sistema: los dominios, los bounded contexts, los principios y las decisiones. Este documento define cómo se implementa esa arquitectura: los estándares, las convenciones, los formatos y las reglas de ingeniería que todo desarrollador debe seguir.

Un desarrollador que incorpore al proyecto puede construir un microservicio nuevo completamente alineado con el ecosistema leyendo este documento junto al Blueprint.

**Ninguna de las reglas aquí definidas es sugerencia. Son contratos de ingeniería.**

---

## Índice

1. [Convenciones de nombres](#1-convenciones-de-nombres)
2. [Variables de entorno](#2-variables-de-entorno)
3. [API Gateway](#3-api-gateway)
4. [Logging estandarizado](#4-logging-estandarizado)
5. [Correlation ID](#5-correlation-id)
6. [Migraciones con Flyway](#6-migraciones-con-flyway)
7. [Docker y red de plataforma](#7-docker-y-red-de-plataforma)
8. [PostgreSQL](#8-postgresql)
9. [Redis — Componente transversal](#9-redis--componente-transversal)
10. [MinIO — Object Storage](#10-minio--object-storage)
11. [Observabilidad](#11-observabilidad)
12. [Health Checks](#12-health-checks)
13. [Seguridad de configuración](#13-seguridad-de-configuración)
14. [Regla de Oro — proceso de implementación](#14-regla-de-oro--proceso-de-implementación)
15. [Versionado de API](#15-versionado-de-api)
16. [Catálogo de permisos](#16-catálogo-de-permisos)
17. [Principios de implementación — YAGNI](#17-principios-de-implementación--yagni)

---

## Nota: Actualización de nombres de servicios

Al establecer los estándares de plataforma se producen los siguientes cambios de nombre respecto al Blueprint v2.0:

| Blueprint v2.0 | Platform Standards v1.0 | Razón |
|---|---|---|
| auth-service | **identity-service** | Nombre más preciso: el dominio es Identidad, no solo Autenticación |
| order-service | **operations-service** | Nombre más preciso: el dominio cubre Órdenes + Despacho + Operaciones |
| notifications-service | **notification-service** | Singular, consistente con el resto de nombres |

El ARCHITECTURE_BLUEPRINT.md debe ser actualizado para reflejar estos nombres en la próxima revisión.

### ADR-010 — Resuelto

**creative-service** → Servicio independiente. Bounded context propio con modelo de dominio diferente: Creative Assets, Design Versions, Approvals, Blueprints, Renders.

**Manufacturing** → Módulo especializado dentro de `operations-service`. Manufacturing es una forma de ejecutar una Work Order con pasos de producción adicionales, no un dominio diferente.

**Catálogo de servicios oficial (15 servicios):**

```
gateway               identity-service      project-service
crm-service           inventory-service     creative-service
operations-service    marketplace-service   financial-service
notification-service  media-service         analytics-service
entity-registry       currency-service      logistics-service
```

---

## 1. Convenciones de nombres

### 1.1 Nombres de microservicios

Formato: `{dominio}-service` en kebab-case.

| Dominio | Nombre del servicio |
|---|---|
| API Gateway | `gateway` |
| Identidad y acceso | `identity-service` |
| Proyectos | `project-service` |
| CRM | `crm-service` |
| Inventario y activos | `inventory-service` |
| Órdenes y operaciones | `operations-service` |
| Diseño creativo | `creative-service` |
| Marketplace | `marketplace-service` |
| Financiero | `financial-service` |
| Notificaciones | `notification-service` |
| Media y archivos | `media-service` |
| Analytics | `analytics-service` |
| Registro de entidades | `entity-registry` |
| Moneda interna | `currency-service` |
| Logística | `logistics-service` |

Regla: el nombre del servicio es el mismo en el código fuente, en el Docker image, en el nombre del container, en el hostname de red y en el directorio del repositorio.

### 1.2 Docker images

Formato: `quantum/{service-name}:{version}`

```
quantum/gateway:1.0.0
quantum/identity-service:1.0.0
quantum/project-service:1.0.0
quantum/crm-service:1.0.0
quantum/inventory-service:1.0.0
quantum/operations-service:1.0.0
quantum/creative-service:1.0.0
quantum/marketplace-service:1.0.0
quantum/financial-service:1.0.0
quantum/notification-service:1.0.0
quantum/media-service:1.0.0
quantum/analytics-service:1.0.0
quantum/entity-registry:1.0.0
quantum/currency-service:1.0.0
quantum/logistics-service:1.0.0
```

Versioning: semántico (`MAJOR.MINOR.PATCH`). El tag `latest` solo existe en desarrollo local. Producción siempre usa una versión explícita.

### 1.3 Bases de datos PostgreSQL

Formato: `{dominio}_db` en snake_case.

```
identity_db
project_db
crm_db
inventory_db
operations_db
creative_db
marketplace_db
financial_db
notification_db
media_db
analytics_db
entity_db
currency_db
```

### 1.4 Usuarios de base de datos

Formato: `svc_{dominio}` en snake_case.

```
svc_identity   → acceso exclusivo a identity_db
svc_project    → acceso exclusivo a project_db
svc_crm        → acceso exclusivo a crm_db
svc_inventory  → acceso exclusivo a inventory_db
svc_operations → acceso exclusivo a operations_db
svc_creative   → acceso exclusivo a creative_db
svc_marketplace→ acceso exclusivo a marketplace_db
svc_financial  → acceso exclusivo a financial_db
svc_notification→ acceso exclusivo a notification_db
svc_media      → acceso exclusivo a media_db
svc_analytics  → acceso exclusivo a analytics_db
svc_entity     → acceso exclusivo a entity_db
svc_currency   → acceso exclusivo a currency_db
```

### 1.5 Redis Streams

Formato: `quantum.{dominio}.{evento}` en dot.notation con kebab-case para el evento.

```
quantum.project.created
quantum.project.state-changed
quantum.project.department-linked
quantum.project.brief-approved
quantum.project.creative-approved
quantum.project.cancelled
quantum.project.closed

quantum.crm.deal-won
quantum.crm.lead-qualified

quantum.creative.asset-created
quantum.creative.design-version-submitted
quantum.creative.approval-requested
quantum.creative.design-approved
quantum.creative.design-rejected
quantum.creative.revision-requested

quantum.operations.order-created
quantum.operations.order-confirmed
quantum.operations.dispatch-started
quantum.operations.dispatch-completed
quantum.operations.order-returned

quantum.inventory.asset-reserved
quantum.inventory.asset-released
quantum.inventory.asset-damaged
quantum.inventory.maintenance-completed

quantum.marketplace.vendor-contracted
quantum.marketplace.resource-delivered

quantum.financial.budget-created
quantum.financial.cost-incurred
quantum.financial.invoice-generated

quantum.notification.requested
quantum.media.document-uploaded
```

**Consumer groups:** Formato `{service-name}::{stream-name}`

```
notification-service::quantum.project.state-changed
analytics-service::quantum.project.closed
operations-service::quantum.project.creative-approved
inventory-service::quantum.operations.order-confirmed
```

Un consumer group por combinación (servicio, stream). Si dos instancias del mismo servicio están activas, comparten el consumer group — Redis Streams entrega cada mensaje a una sola instancia del grupo.

### 1.6 Buckets MinIO

Nombres en kebab-case singular.

```
document    → documentos estructurados: briefs, contratos, propuestas, facturas
creative    → activos creativos: renders, mood boards, diseños, videos
asset       → imágenes de inventario: fotos de producto, modelos 3D, fichas técnicas
avatar      → imágenes de perfil: usuarios, empresas
export      → exportaciones generadas: reportes, CSVs, PDFs del sistema
temp        → uploads temporales (TTL: 24 horas, limpieza automática)
```

Estructura de path dentro del bucket:
```
{entity-type}/{entity-id}/{uuid}.{extension}

Ejemplo:
document/projects/550e8400-e29b-41d4-a716-446655440000/brief_inicial.pdf
creative/projects/550e8400-e29b-41d4-a716-446655440000/moodboard_v2.png
asset/inventory-items/a1b2c3d4-e5f6-7890-abcd-ef1234567890/foto_frontal.jpg
```

### 1.7 Variables y constantes en código

| Contexto | Convención |
|---|---|
| Variables de entorno | SCREAMING_SNAKE_CASE |
| Clases / Interfaces | PascalCase |
| Métodos / Funciones | camelCase |
| Constantes de código | SCREAMING_SNAKE_CASE |
| Columnas de BD | snake_case |
| Tablas de BD | snake_case, plural |
| Endpoints REST | kebab-case, plural |
| Eventos de dominio | PascalCase |
| Nombres de streams | dot.notation + kebab-case |

---

## 2. Variables de entorno

### 2.1 Estructura estándar

Todo microservicio del sistema acepta las siguientes variables de entorno. Las marcadas con `*` son obligatorias en todos los servicios.

```bash
# ──────────────────────────────────────────
# RUNTIME
# ──────────────────────────────────────────
SERVICE_NAME=project-service            # * nombre del servicio (match con naming convention)
SERVICE_PORT=8082                       # * puerto en el que escucha
LOG_LEVEL=info                          # * nivel de log: error | warn | info | debug

# Perfil de Spring Boot (solo para servicios Spring Boot)
SPRING_PROFILES_ACTIVE=production       # production | development | test

# Entorno de Node (solo para servicios NestJS)
NODE_ENV=production                     # production | development | test

# ──────────────────────────────────────────
# DATABASE
# ──────────────────────────────────────────
DB_HOST=postgresql                      # * hostname del servidor PostgreSQL
DB_PORT=5432                            # * puerto
DB_NAME=project_db                      # * nombre de la base de datos lógica
DB_USERNAME=svc_project                 # * usuario con acceso exclusivo a esta BD
DB_PASSWORD=...                         # * contraseña (nunca en código fuente)
DB_POOL_MIN=2                           # mínimo de conexiones en el pool
DB_POOL_MAX=20                          # máximo de conexiones en el pool

# ──────────────────────────────────────────
# REDIS
# ──────────────────────────────────────────
REDIS_HOST=redis                        # * hostname del servidor Redis
REDIS_PORT=6379                         # * puerto
REDIS_PASSWORD=...                      # contraseña (vacío en desarrollo local)
REDIS_STREAM_PREFIX=quantum             # * prefijo de todos los streams de este sistema

# ──────────────────────────────────────────
# AUTENTICACIÓN / JWT
# ──────────────────────────────────────────
# Todos los servicios necesitan la clave pública para verificar tokens
JWT_PUBLIC_KEY=...                      # * clave pública RSA en formato PEM (una línea, \n escapado)
# Solo identity-service necesita la clave privada
JWT_PRIVATE_KEY=...                     # clave privada RSA (SOLO identity-service)

# ──────────────────────────────────────────
# COMUNICACIÓN INTERNA ENTRE SERVICIOS
# ──────────────────────────────────────────
INTERNAL_SERVICE_KEY=...               # * clave compartida para llamadas service-to-service

# ──────────────────────────────────────────
# MINIO (solo servicios que gestionan archivos)
# ──────────────────────────────────────────
MINIO_ENDPOINT=http://minio:9000
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
MINIO_DEFAULT_REGION=us-east-1

# ──────────────────────────────────────────
# OBSERVABILIDAD
# ──────────────────────────────────────────
ZIPKIN_URL=http://zipkin:9411           # * endpoint de Zipkin para trazas
PROMETHEUS_ENABLED=true                 # * habilita el endpoint de métricas
```

### 2.2 Reglas de gestión de secretos

1. Las variables marcadas como secretas (contraseñas, claves, tokens) **nunca** se definen en código fuente ni en archivos versionados
2. En desarrollo local: archivo `.env.local` (excluido de git por `.gitignore`)
3. En producción: GitHub Actions Secrets inyectados como variables de entorno al container
4. Los archivos `.env.example` sí se versionan, con valores de ejemplo no reales
5. Nunca usar valores de producción en desarrollo local

### 2.3 Archivo .env.example obligatorio

Todo microservicio nuevo debe incluir un `.env.example` en su directorio raíz con todas las variables requeridas y valores de ejemplo. Este archivo se versiona en git.

---

## 3. API Gateway

### 3.1 Responsabilidades del Gateway

El Gateway es el único punto de entrada externo al sistema. Su responsabilidad es exclusivamente de infraestructura de transporte, nunca de negocio.

**Hace:**

| Responsabilidad | Descripción |
|---|---|
| Autenticación | Valida la firma del JWT en cada request entrante. Si el token es inválido o está expirado, devuelve 401 antes de enrutar. |
| Extracción de identidad | Extrae los claims del JWT válido y los agrega como header `X-Authenticated-User` para los servicios downstream |
| Routing | Enruta cada request al servicio correcto basado en el path prefix |
| Correlation ID | Genera un `X-Correlation-ID` (UUID v4) si el request no trae uno. Propaga el existente si ya viene |
| Rate Limiting | Limita el número de requests por usuario y por IP usando Redis. Responde 429 cuando se supera el límite |
| Circuit Breaker | Deja de enrutar tráfico a un servicio no disponible. Responde 503 hasta que el servicio se recupere |
| CORS | Gestiona las políticas de Cross-Origin Resource Sharing para el frontend |
| Request Logging | Registra cada request con método, path, status code, duración y correlationId |

**Nunca hace:**

| Prohibición | Razón |
|---|---|
| Lógica de negocio de ningún dominio | Cualquier regla de negocio en el Gateway viola el principio de Bounded Context |
| Consultas a bases de datos | El Gateway no tiene conexión a ninguna base de datos |
| Llamadas a múltiples servicios para agregar respuestas | Eso es responsabilidad de un BFF o del frontend. El Gateway enruta 1:1 |
| Transformación del cuerpo del request o response | El Gateway no modifica payloads, solo headers |
| Decisiones de autorización detalladas | "Este usuario puede ver este proyecto específico" es lógica del project-service, no del Gateway |
| Caché de respuestas de negocio | El Gateway puede hacer health caching interno pero no caché de datos de negocio |

### 3.2 Headers de plataforma

El Gateway garantiza los siguientes headers en cada request que llega a un servicio downstream:

```
X-Correlation-ID: {uuid}          → generado por el Gateway si no venía en el request
X-Authenticated-User: {json_b64}  → claims del JWT codificados en base64
X-Forwarded-For: {ip}             → IP original del cliente
X-Request-Start: {timestamp_ms}   → momento de entrada al Gateway
```

Los servicios **confían** en estos headers. No re-validan el JWT. La seguridad de estos headers está garantizada por el hecho de que ningún servicio es accesible directamente desde el exterior — solo a través del Gateway dentro de la red `quantum-network`.

### 3.3 Contrato de errores del Gateway

El Gateway devuelve errores en formato estándar:

```json
{
  "error": "UNAUTHORIZED",
  "message": "Token JWT inválido o expirado",
  "correlationId": "uuid"
}
```

Códigos de error del Gateway (no de servicios):

| Situación | HTTP Status | Error Code |
|---|---|---|
| Token ausente | 401 | `MISSING_TOKEN` |
| Token inválido o expirado | 401 | `INVALID_TOKEN` |
| Rate limit excedido | 429 | `RATE_LIMIT_EXCEEDED` |
| Servicio no disponible (circuit open) | 503 | `SERVICE_UNAVAILABLE` |
| Ruta no encontrada | 404 | `ROUTE_NOT_FOUND` |

---

## 4. Logging estandarizado

### 4.1 Formato JSON obligatorio

Todo log del sistema es un objeto JSON en una sola línea. No se permiten logs en texto plano.

**Campos obligatorios en todo log:**

```json
{
  "timestamp": "2026-08-03T14:30:00.123Z",
  "level": "INFO",
  "service": "project-service",
  "version": "1.0.0",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Project created successfully"
}
```

**Campos adicionales para requests HTTP:**

```json
{
  "timestamp": "...",
  "level": "INFO",
  "service": "project-service",
  "version": "1.0.0",
  "correlationId": "uuid",
  "requestId": "uuid",
  "traceId": "hex",
  "spanId": "hex",
  "userId": "uuid | null",
  "method": "POST",
  "path": "/api/v1/projects",
  "statusCode": 201,
  "durationMs": 145,
  "message": "POST /api/v1/projects → 201 (145ms)"
}
```

**Campos adicionales para eventos:**

```json
{
  "timestamp": "...",
  "level": "INFO",
  "service": "project-service",
  "version": "1.0.0",
  "correlationId": "uuid",
  "eventType": "ProjectCreated",
  "aggregateId": "uuid",
  "aggregateType": "Project",
  "message": "Event published: ProjectCreated"
}
```

**Campos adicionales para errores:**

```json
{
  "timestamp": "...",
  "level": "ERROR",
  "service": "project-service",
  "version": "1.0.0",
  "correlationId": "uuid",
  "error": "PROJECT_NOT_FOUND",
  "errorMessage": "Project with id '...' not found",
  "stackTrace": "...",
  "message": "Unhandled exception in ProjectController.getProject"
}
```

### 4.2 Niveles de log

| Nivel | Cuándo usar |
|---|---|
| `ERROR` | Excepciones no manejadas, fallos del sistema, errores que requieren atención inmediata |
| `WARN` | Excepciones manejadas, operaciones degradadas, reintentos, datos en estado inesperado |
| `INFO` | Eventos de negocio importantes: creación de entidades, transiciones de estado, publicación de eventos |
| `DEBUG` | Flujo detallado de ejecución para diagnóstico (desactivado en producción) |

### 4.3 Reglas de seguridad en logs

Ningún log puede contener:
- Contraseñas, tokens JWT, API keys, claves privadas
- Números de tarjeta de crédito o datos financieros personales
- Datos personales identificables (email, teléfono, dirección) en nivel INFO o superior
- Payloads completos de request en producción (pueden contener datos sensibles)

Los campos con datos sensibles se enmascaran: `"email": "c***@brandex.global"`, `"password": "[REDACTED]"`.

---

## 5. Correlation ID

### 5.1 Definición

El Correlation ID es un identificador único (UUID v4) que permite rastrear una solicitud a lo largo de todos los servicios que participan en su resolución. Es el hilo conductor del sistema de trazabilidad distribuida.

### 5.2 Ciclo de vida

```
1. Cliente envía request
     └── Si el request incluye X-Correlation-ID → el Gateway lo usa
     └── Si no incluye X-Correlation-ID → el Gateway genera un UUID v4

2. Gateway propaga X-Correlation-ID a todos los headers del request downstream

3. Cada servicio:
     ├── Extrae X-Correlation-ID del header entrante
     ├── Incluye correlationId en todos los logs de esa request
     ├── Incluye correlationId en cualquier evento publicado a Redis Streams
     ├── Incluye correlationId en todos los headers de salida (llamadas a otros servicios)
     └── Incluye correlationId en la respuesta de error (nunca en respuestas exitosas)

4. Zipkin recibe el correlationId como parte del contexto de tracing
```

### 5.3 Reglas de propagación

- Un servicio que recibe un correlationId **nunca lo modifica ni lo reemplaza**
- Un servicio que genera llamadas outbound **siempre** incluye el correlationId actual en los headers
- Un evento publicado a Redis Streams **siempre** incluye el correlationId en su payload
- Un servicio que consume un evento **usa el correlationId del evento** para sus propios logs de ese procesamiento
- En respuestas de error HTTP, el campo `correlationId` es obligatorio para que el equipo pueda rastrear el fallo

---

## 6. Migraciones con Flyway

### 6.1 Flyway como único mecanismo

Toda modificación al esquema de base de datos de cualquier servicio se realiza exclusivamente mediante migraciones de Flyway. Están prohibidos:
- Cambios manuales a través de clientes SQL
- Scripts ad hoc ejecutados sin versionar
- `ddl-auto: create`, `ddl-auto: create-drop` o `ddl-auto: update` en cualquier entorno que no sea test unitario

El modo permitido en staging y producción: `ddl-auto: validate`

### 6.2 Convención de nombres de archivos

Formato: `V{número}__{descripción}.sql`

```
Reglas:
- {número}: entero secuencial sin ceros a la izquierda (V1, V2, V3...)
- {descripción}: snake_case, verbo en infinitivo + objeto
- Separador: doble guion bajo (__)
- Extensión: .sql

Ejemplos correctos:
  V1__create_projects_table.sql
  V2__add_phase_column_to_project_states.sql
  V3__seed_project_phases.sql
  V4__seed_project_states.sql
  V5__create_project_members_table.sql

Ejemplos incorrectos:
  V01__create_projects.sql      ← ceros a la izquierda
  V1_create_projects.sql        ← un solo guion
  V1__CreateProjects.sql        ← PascalCase en descripción
  v1__create_projects.sql       ← V en minúscula
```

### 6.3 Estructura de directorio

```
{service}/
  src/
    main/
      resources/
        db/
          migration/
            V1__create_{entidad_principal}_table.sql
            V2__...
```

### 6.4 Reglas de inmutabilidad

Una migración aplicada **nunca se modifica**. Si se necesita corregir algo que aplicó una migración anterior:
- Crear una nueva migración que corrija el estado
- Nunca editar la migración original

Si se modifica una migración ya aplicada, Flyway lanzará un error de checksum y el servicio no arrancará — esto es intencional.

### 6.5 Datos de configuración como migraciones

Los datos que son configuración del sistema (estados de proyecto, fases, departamentos iniciales) se insertan mediante migraciones de seed, no a través de código de aplicación.

```sql
-- V4__seed_project_phases.sql
INSERT INTO project_phases (code, name, color_base, color_peak, sort_order) VALUES
  ('EXPLORATION', 'Exploración', '#E3F2FD', '#1565C0', 1),
  ('APPROVAL',    'Aprobación',  '#E8F5E9', '#2E7D32', 2),
  ('EXECUTION',   'Ejecución',   '#FFF8E1', '#F57F17', 3),
  ('CLOSURE',     'Cierre',      '#F3E5F5', '#6A1B9A', 4);
```

---

## 7. Docker y red de plataforma

### 7.1 Red única de plataforma

Todos los contenedores del sistema pertenecen a una única red privada:

```
Nombre: quantum-network
Tipo: bridge
Driver: bridge
```

Ningún contenedor se comunica con otro fuera de esta red. Los servicios se descubren por nombre de contenedor (hostname = nombre del servicio según la convención de nombres).

### 7.2 Exposición de puertos

| Entorno | Comportamiento |
|---|---|
| Desarrollo local | Los servicios exponen puertos al host para facilitar debugging y herramientas externas |
| Producción | **Solo el Gateway expone un puerto al exterior.** El resto de servicios son accesibles únicamente dentro de `quantum-network` |

En producción, el único puerto expuesto al exterior es el del Gateway (`:443` con TLS terminado en el balanceador, o `:8080` si el TLS lo gestiona un proxy externo).

### 7.3 Nomenclatura de containers

El nombre del container es idéntico al nombre del servicio:

```yaml
services:
  project-service:
    container_name: project-service
    hostname: project-service
    networks:
      - quantum-network
```

Esto garantiza que `http://project-service:8082` es la dirección correcta desde cualquier servicio dentro de la red.

### 7.4 .dockerignore obligatorio

Todo microservicio incluye un `.dockerignore` en su directorio raíz que excluye al menos:

```
.env
.env.local
.env.*
!.env.example
node_modules/
*.log
.git/
target/
build/
dist/
secrets/
*.pem
*.key
credentials.json
```

---

## 8. PostgreSQL

### 8.1 Configuración de la instancia

```
Versión:    PostgreSQL 16
Instancia:  Una única instancia compartida
Separación: Bases de datos lógicas por servicio
Acceso:     Un usuario dedicado por base de datos
```

### 8.2 Permisos por usuario

Cada usuario de servicio tiene exactamente estos permisos sobre su base de datos, y ninguno más:

```sql
GRANT CONNECT ON DATABASE {service}_db TO svc_{service};
GRANT USAGE ON SCHEMA public TO svc_{service};
GRANT CREATE ON SCHEMA public TO svc_{service};
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO svc_{service};
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO svc_{service};
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO svc_{service};
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
  GRANT USAGE, SELECT ON SEQUENCES TO svc_{service};
```

Ningún usuario tiene: `SUPERUSER`, `CREATEDB`, `CREATEROLE`, acceso a otras bases de datos.

### 8.3 Configuración de connection pool

Los servicios Spring Boot usan HikariCP (configurado en application.yml):

```
minimum-idle: 2
maximum-pool-size: 20
connection-timeout: 30000   (ms)
idle-timeout: 600000        (ms)
max-lifetime: 1800000       (ms)
```

Los servicios NestJS usan TypeORM connection pool con valores equivalentes.

El total de conexiones por instancia PostgreSQL no debe superar 150. Con 12 servicios a 20 conexiones máximas = 240 en el peor caso. Si se alcanza ese límite, se interpone PgBouncer en modo transaction pooling.

### 8.4 Prohibiciones absolutas

- Un servicio nunca tiene credenciales de la base de datos de otro servicio
- No existen foreign keys entre bases de datos distintas
- No existen views ni stored procedures que accedan a más de una base de datos
- No existen JOINs cross-database

Cualquier necesidad de datos de otro dominio se satisface a través de la API del servicio propietario o consumiendo sus eventos.

---

## 9. Redis — Componente transversal

### 9.1 Redis como plataforma, no como caché

Redis no es un caché añadido por conveniencia. Es un componente de plataforma con múltiples responsabilidades bien definidas:

| Responsabilidad | Descripción |
|---|---|
| **Event Broker (Redis Streams)** | Comunicación asíncrona entre servicios. El canal principal de eventos de dominio. |
| **Rate Limiting** | El Gateway registra y controla la tasa de requests por usuario e IP. |
| **Distributed Locks** | Operaciones que deben ser atómicas entre múltiples instancias del mismo servicio. |
| **Idempotency Keys** | Registro de eventIds procesados para garantizar idempotencia de consumidores. |
| **Application Cache** | Respuestas frecuentes con TTL. Prefijo por servicio para evitar colisiones. |

### 9.2 Abstracción del broker — Principio de agnosis

**El código de negocio nunca llama a Redis directamente.**

Toda publicación y consumo de eventos ocurre a través de una interfaz `EventBus`. La implementación actual es `RedisStreamEventBus`. Esta abstracción garantiza que, si en el futuro el volumen de eventos justifica migrar a Kafka, el cambio ocurre en una única clase de infraestructura, sin tocar ningún servicio de dominio.

```
Interfaz:      IEventBus
  - publish(event: DomainEvent): void
  - subscribe(stream: string, handler: EventHandler): void

Implementación: RedisStreamEventBus
  - Implementa IEventBus usando Redis Streams
  - Gestiona consumer groups, ACKs, y reconexión

Implementación futura (cuando aplique):
  KafkaEventBus
  - Implementa IEventBus usando Kafka
  - El código de negocio no cambia
```

### 9.3 Convenciones de caché

Formato de clave: `{service}:{entity-type}:{entity-id}`

```
project:projects:550e8400-e29b-41d4-a716-446655440000        → TTL: 5 minutos
project:project-states:all                                     → TTL: 1 hora (rara vez cambia)
identity:users:550e8400-e29b-41d4-a716-446655440000           → TTL: 15 minutos
```

Regla: nunca cachear datos que deben ser siempre consistentes (ej: stock de un activo durante una reserva). Solo cachear datos de lectura frecuente y con tolerancia a eventual consistency.

### 9.4 Idempotency Keys

Formato: `idempotency:{service}:{event-id}`

Cuando un consumidor procesa un evento, registra el `eventId` con un TTL de 24 horas. Antes de procesar un evento, verifica si el `eventId` ya existe. Si existe, el procesamiento se omite.

Este mecanismo garantiza que procesar el mismo evento dos veces (por redelivery de Redis Streams) no produce efectos duplicados.

### 9.5 Distributed Locks

Formato de clave de lock: `lock:{service}:{recurso}:{id}`

```
lock:inventory:asset:550e8400...    → lock durante reserva de activo
lock:operations:dispatch:uuid       → lock durante creación de dispatch
```

TTL máximo de un lock: 30 segundos. Si el servicio falla mientras tiene el lock, el TTL garantiza que el recurso se libera automáticamente.

---

## 10. MinIO — Object Storage

### 10.1 Buckets por naturaleza del contenido

Los buckets se organizan por el tipo de contenido, no por departamento ni por proyecto. Esta organización es agnóstica a la estructura organizacional de Brandex y se mantiene válida si la empresa crece, cambia departamentos o abre nuevas líneas de negocio.

```
document     → Documentos estructurados: briefs, contratos, propuestas, facturas, actas
creative     → Activos creativos: renders, mood boards, diseños, storyboards, videos de concepto
asset        → Imágenes de inventario físico: fotos de producto, modelos 3D, fichas técnicas
avatar       → Imágenes de perfil: usuarios, empresas clientes, empresas proveedoras
export       → Archivos generados por el sistema: reportes, CSVs, PDFs de exportación
temp         → Uploads temporales en proceso de validación o procesamiento (TTL: 24 horas)
```

### 10.2 Estructura de path

```
{bucket}/{entity-type}/{entity-id}/{uuid}.{extension}
```

Ejemplos:
```
document/projects/550e8400.../brief_cliente.pdf
creative/projects/550e8400.../concepto_visual_v3.png
asset/inventory-items/a1b2c3d4.../foto_frontal.jpg
asset/inventory-items/a1b2c3d4.../ficha_tecnica.pdf
avatar/users/e5f6a7b8.../profile.jpg
export/projects/550e8400.../cierre_financiero_2026.xlsx
```

El `uuid` en el nombre del archivo garantiza que no existan colisiones aunque dos archivos del mismo tipo se asocien a la misma entidad.

### 10.3 Acceso a archivos

Los archivos en MinIO no se sirven a través del servidor de aplicación. Se sirven directamente desde MinIO usando URLs pre-firmadas o URLs públicas dependiendo del tipo de contenido:

```
document, export  → URL pre-firmada (acceso temporal, caducidad configurable)
creative, asset   → URL pre-firmada o pública según política del bucket
avatar            → URL pública (contenido no sensible)
temp              → URL pre-firmada de corta duración
```

### 10.4 Responsabilidad de media-service

La única entidad que tiene credenciales de MinIO es `media-service`. Los demás servicios solicitan operaciones de archivo a `media-service` mediante su API, no llamando a MinIO directamente.

---

## 11. Observabilidad

### 11.1 Los tres pilares en todo servicio

Todo microservicio implementa los tres pilares de observabilidad desde el día 1 de desarrollo. No se añaden después.

**Logs:** JSON estructurado según el formato definido en la sección 4. Exportados a stdout para captura por el sistema de logging del host.

**Métricas:** Endpoint `/actuator/metrics` (Spring Boot) o `/metrics` (NestJS con Prometheus adapter). Incluye métricas técnicas (latencia, error rate, pool size) y métricas de negocio (entidades creadas, transiciones ejecutadas).

**Trazas:** Integración con Zipkin. Cada request genera un span con el correlationId como contexto. Las llamadas entre servicios propagan el trace context.

### 11.2 Métricas de negocio obligatorias

Además de las métricas técnicas automáticas, cada servicio expone métricas de negocio específicas de su dominio:

```
project_service_projects_created_total
project_service_state_transitions_total{from="...", to="..."}
project_service_projects_active_gauge

inventory_service_assets_reserved_total
inventory_service_assets_in_maintenance_gauge

operations_service_orders_created_total
operations_service_dispatches_completed_total
```

Formato: `{service_name}_{metric_description}_{unit}`

---

## 12. Health Checks

### 12.1 Endpoints obligatorios

Todo microservicio expone dos endpoints de salud:

```
GET /health/live    → Liveness: ¿está el proceso vivo?
GET /health/ready   → Readiness: ¿puede recibir tráfico?
```

Para servicios Spring Boot, estos mapean a `/actuator/health/liveness` y `/actuator/health/readiness`.

### 12.2 Contrato de respuesta

**Servicio saludable (200):**
```json
{
  "status": "UP",
  "service": "project-service",
  "version": "1.0.0",
  "timestamp": "2026-08-03T14:30:00Z"
}
```

**Servicio no listo (503):**
```json
{
  "status": "DOWN",
  "service": "project-service",
  "version": "1.0.0",
  "timestamp": "2026-08-03T14:30:00Z",
  "checks": {
    "database": "DOWN",
    "redis": "UP"
  }
}
```

### 12.3 Qué verifica Readiness

El endpoint `/health/ready` retorna `UP` solo cuando **todas** las dependencias críticas del servicio están disponibles:
- Conexión a su base de datos PostgreSQL
- Conexión a Redis (si el servicio usa Redis)
- Cualquier dependencia crítica adicional propia del dominio

Si cualquier dependencia crítica está caída, el servicio retorna 503 y el Gateway deja de enrutar tráfico hacia él.

---

## 13. Seguridad de configuración

### 13.1 Archivos requeridos en todo servicio

Todo directorio de microservicio contiene obligatoriamente:

```
{service}/
  .gitignore          → excluye secretos, builds, dependencias
  .dockerignore       → excluye secretos, builds, node_modules/target
  .env.example        → template de variables de entorno (sin valores reales)
```

### 13.2 Contenido mínimo del .gitignore por tecnología

**Spring Boot:**
```gitignore
target/
*.class
.env
.env.local
.env.*
!.env.example
*.pem
*.key
application-production.yml
application-staging.yml
secrets/
credentials*.json
```

**NestJS:**
```gitignore
node_modules/
dist/
.env
.env.local
.env.*
!.env.example
*.pem
*.key
secrets/
credentials*.json
```

### 13.3 Rotación de secretos

| Secreto | Frecuencia de rotación |
|---|---|
| `INTERNAL_SERVICE_KEY` | Cada 90 días |
| `JWT_PRIVATE_KEY` | Cada 180 días (requiere despliegue coordinado) |
| Contraseñas de BD | Cada 90 días |
| MinIO credentials | Cada 90 días |
| Contraseña de Redis | Cada 90 días |

---

## 14. Regla de Oro — proceso de implementación

Todo el equipo sigue este proceso antes de implementar cualquier funcionalidad. Sin excepciones.

### Los 8 pasos

1. **Problema de negocio** — ¿Qué necesidad operacional real de Brandex estamos resolviendo?
2. **Bounded context** — ¿A qué dominio del Blueprint pertenece esta funcionalidad?
3. **Validación contra Blueprint** — ¿El Blueprint ya contempla esta funcionalidad? Si no la contempla, hay que actualizar el Blueprint con un ADR antes de implementar.
4. **Diseño de la solución** — ¿Cómo se implementa dentro del dominio responsable?
5. **Impacto sobre otros servicios** — ¿Qué otros servicios se ven afectados? ¿Qué contratos cambian?
6. **Contratos** — APIs REST, DTOs, eventos publicados y consumidos, payloads, errores.
7. **Implementación** — Código siguiendo los estándares de este documento.
8. **Validación** — ¿La implementación respeta el Blueprint y estos estándares?

### Criterios de parada

Si en cualquier punto se detecta alguna de las siguientes situaciones, la implementación se detiene y se propone una corrección antes de continuar:

- La funcionalidad requiere que un servicio acceda a la BD de otro servicio
- La implementación crea acoplamiento temporal entre servicios (llamada síncrona donde debería haber evento asíncrono)
- Un servicio está creciendo más allá de su bounded context definido
- Aparece lógica de negocio en el Gateway
- Se almacenan datos de negocio en localStorage del frontend
- Un enum en el código reemplaza datos que deben estar en base de datos
- Se detecta duplicación de responsabilidades entre dos servicios

---

## 15. Versionado de API

Implementación de ADR-012. Ver la decisión completa en `ARCHITECTURE_BLUEPRINT.md`.

### 15.1 Estructura de paths

```
/api/v{n}/{recurso}             → endpoints públicos (expuestos por Gateway)
/internal/{recurso}             → endpoints internos (service-to-service, sin versión)
/actuator/health                → Spring Boot Actuator (no versionar)
/health/live  /health/ready     → NestJS health (no versionar)
```

### 15.2 Convenciones de ruta

```
GET    /api/v1/projects              → listar
GET    /api/v1/projects/{id}         → obtener por ID
POST   /api/v1/projects              → crear
PATCH  /api/v1/projects/{id}         → actualización parcial (preferir sobre PUT)
DELETE /api/v1/projects/{id}         → eliminar (soft delete cuando aplique)

Sub-recursos:
GET    /api/v1/projects/{id}/members
POST   /api/v1/projects/{id}/members
DELETE /api/v1/projects/{id}/members/{memberId}
```

Reglas:
- Los recursos son siempre plural y en kebab-case: `/work-orders`, `/project-members`
- Las acciones que no son CRUD van como sub-rutas en verbo sustantivado: `/api/v1/projects/{id}/approval` (POST), `/api/v1/auth/refresh` (POST)
- Nunca verbos en la ruta: ~~`/api/v1/getProjects`~~, ~~`/api/v1/approveProject`~~

### 15.3 Headers de respuesta

Toda respuesta de un endpoint versionado incluye:

```http
X-API-Version: 1
X-Correlation-Id: {correlationId}
```

Endpoints deprecados agregan:

```http
Deprecation: true
Sunset: Sat, 01 Aug 2026 00:00:00 GMT
Link: </api/v2/projects>; rel="successor-version"
```

### 15.4 Errores estandarizados (RFC 7807 Problem Details)

```json
{
  "type": "https://quantum.brandex.global/errors/resource-not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Project with id '550e8400-e29b-41d4-a716-446655440000' does not exist.",
  "instance": "/api/v1/projects/550e8400-e29b-41d4-a716-446655440000",
  "correlationId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

---

## 16. Catálogo de permisos

### 16.1 Fuente de verdad única

Los permisos de la plataforma viven en un único archivo YAML. Ningún equipo modifica manualmente `Permission.java` o `Permission.ts`. El enum es generado automáticamente durante el proceso de build.

```
Backend/
└── permissions.yaml       ← fuente de verdad (único archivo a editar)

scripts/
└── generate-permissions.sh   ← genera los enums para Java y TypeScript
```

### 16.2 Formato de permissions.yaml

```yaml
# Backend/permissions.yaml
# Catálogo oficial de permisos de Quantum ERP.
# Actualizar este archivo y ejecutar scripts/generate-permissions.sh
# para regenerar Permission.java y Permission.ts

version: "1.0"

permissions:

  # ── Plataforma (identity-service) ─────────────────────
  USERS_READ:              { resource: USERS,  description: "Leer perfiles y listas de usuarios" }
  USERS_CREATE:            { resource: USERS,  description: "Crear nuevas cuentas de usuario" }
  USERS_UPDATE:            { resource: USERS,  description: "Modificar datos de usuario" }
  USERS_SUSPEND:           { resource: USERS,  description: "Suspender acceso de un usuario" }
  USERS_DEACTIVATE:        { resource: USERS,  description: "Desactivar permanentemente un usuario" }

  ROLES_READ:              { resource: ROLES,  description: "Consultar roles existentes" }
  ROLES_CREATE:            { resource: ROLES,  description: "Crear nuevos roles (solo ROOT)" }
  ROLES_UPDATE:            { resource: ROLES,  description: "Modificar roles existentes (solo ROOT)" }
  ROLES_ASSIGN:            { resource: ROLES,  description: "Asignar un rol a un usuario" }
  ROLES_REVOKE:            { resource: ROLES,  description: "Revocar un rol de un usuario" }

  SYSTEM_SERVICE_REGISTER: { resource: SYSTEM, description: "Registrar un nuevo microservicio" }
  SYSTEM_BOOTSTRAP:        { resource: SYSTEM, description: "Ejecutar secuencia de bootstrap" }

  # ── project-service (agregar en el sprint de project-service) ──
  # PROJECT_READ:           { resource: PROJECTS, description: "..." }
  # PROJECT_CREATE:         { resource: PROJECTS, description: "..." }
  # ...
```

### 16.3 Script generador

```bash
# scripts/generate-permissions.sh
# Uso: ./scripts/generate-permissions.sh
# Genera: Backend/services/identity-service/src/main/java/.../Permission.java
#         Backend/shared/auth/src/Permission.ts

YAML_FILE="Backend/permissions.yaml"
JAVA_OUT="Backend/services/identity-service/src/main/java/global/brandex/quantum/identity/authorization/domain/model/Permission.java"
TS_OUT="Backend/shared/auth/src/Permission.ts"

# El generador lee permissions.yaml y produce los enum files.
# Ejecutar como pre-compile step en Maven (exec-maven-plugin) y
# como prebuild script en package.json para NestJS.
```

**Integración en el build:**

Maven (`pom.xml`):
```xml
<plugin>
  <groupId>org.codehaus.mojo</groupId>
  <artifactId>exec-maven-plugin</artifactId>
  <executions>
    <execution>
      <id>generate-permissions</id>
      <phase>generate-sources</phase>
      <goals><goal>exec</goal></goals>
      <configuration>
        <executable>${project.basedir}/../../../../scripts/generate-permissions.sh</executable>
      </configuration>
    </execution>
  </executions>
</plugin>
```

`package.json` (NestJS):
```json
{
  "scripts": {
    "prebuild": "../../scripts/generate-permissions.sh",
    "build": "nest build"
  }
}
```

### 16.4 Roles de sistema (sembrados en Flyway V2)

| Nombre | is_super_admin | Descripción |
|---|---|---|
| `ROOT` | `true` | Bypass total de autorización. Sin lista de permisos. Solo para administración de plataforma. |
| `SYSTEM_ADMIN` | `false` | Administrador de la plataforma. Gestiona usuarios y asignación de roles. |

Los roles de negocio (`PROJECT_MANAGER`, `CRM_MANAGER`, etc.) se crean en el sprint de su respectivo dominio — nunca antes.

### 16.5 Redis — claves de caché de autorización

```
quantum:auth:session:{sessionId}     → { userId, status, expiresAt }           TTL: tiempo restante de sesión
quantum:auth:permissions:{userId}    → { roles[], permissions[], isSuperAdmin } TTL: 5 minutos
```

Estas claves son invalidadas inmediatamente cuando identity-service modifica roles, permisos o el status de un usuario.

---

## 17. Principios de implementación — YAGNI

**YAGNI — You Aren't Gonna Need It**

No se implementa funcionalidad anticipando necesidades futuras hipotéticas. Solo se documenta.

### 17.1 Qué significa en la práctica

| Situación | Correcto | Incorrecto |
|---|---|---|
| "Algún día habrá ABAC" | Documentar en ADR-011. No escribir código. | Crear clases de ABAC vacías "para cuando llegue el día" |
| "Quizás se necesite multiempresa" | Documentar como riesgo en el Blueprint. | Agregar un campo `tenant_id` a todas las tablas ahora |
| "Feature flags podrían ser útiles" | Registrar como decisión futura. | Diseñar un motor de feature flags en Phase 1 |
| "Probablemente necesitemos exportar a Excel" | Agregar al backlog cuando haya demanda real. | Crear el exportador porque "seguro lo pedirán" |

### 17.2 Cuándo sí se anticipa

- **Extensibilidad estructural**: si el costo de un campo o una interfaz hoy es mínimo y la ausencia después es catastrófica. Ejemplo: `auth_method ENUM` en `users` — anticipar la existencia de dos métodos es correcto porque cambiar el modelo después implica migración.
- **Contratos de API**: agregar campos `nullable` en la respuesta sin romper clientes existentes está permitido.
- **ADRs y documentación**: documentar decisiones futuras es gratis. Implementarlas no.

### 17.3 Regla de aplicación al Technical Design

Antes de escribir una clase, un endpoint, o una tabla, pregunta:

> ¿Existe un requisito concreto y aprobado hoy que justifique esto?

Si la respuesta es "probablemente", "algún día" o "por si acaso" — no se implementa.

---

## Historial de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| 1.1 | 2026-08-03 | Secciones 15–17: Versionado de API (ADR-012), Catálogo de permisos (permissions.yaml + generador), YAGNI. Índice actualizado. |
| 1.0 | 2026-08-03 | Documento inicial. Estándares de plataforma para Quantum ERP. |

---

*Este documento es complementario al `ARCHITECTURE_BLUEPRINT.md`. Los estándares aquí definidos implementan las decisiones arquitectónicas del Blueprint. Cualquier cambio en estos estándares debe justificarse en relación con el Blueprint.*

*Platform Standards v1.0 — Quantum ERP — Brandex Global — 2026-08-03*
