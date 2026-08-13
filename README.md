# Quantum ERP — Brandex Rental Platform

Sistema de gestión empresarial para la operación de eventos, alquiler de activos, logística y CRM comercial de **Brandex Global**. Arquitectura de microservicios con frontend React y backend mixto (Kotlin/Spring Boot + NestJS).

---

## Tabla de Contenidos

1. [Arquitectura](#arquitectura)
2. [Módulos y Features Actuales](#módulos-y-features-actuales)
3. [Módulos Pendientes / En Construcción](#módulos-pendientes--en-construcción)
4. [Infraestructura](#infraestructura)
5. [Tech Stack](#tech-stack)
6. [Flujo de Trabajo — GitHub Flow](#flujo-de-trabajo--github-flow)
7. [Roles del Equipo](#roles-del-equipo)
8. [Setup Local](#setup-local)
9. [Variables de Entorno](#variables-de-entorno)

---

## Arquitectura

```
                        ┌─────────────────────────────────────────────┐
                        │              Frontend (React 18)             │
                        │   Vite · React Router v6 · Zustand · TanStack│
                        └────────────────────┬────────────────────────┘
                                             │ HTTP / WebSocket
                        ┌────────────────────▼────────────────────────┐
                        │        API Gateway  :80                      │
                        │   Spring Cloud Gateway · JWT RS256 · Rate Limiter│
                        └──┬──────┬──────┬──────┬──────┬─────────────┘
                           │      │      │      │      │
              ┌────────────▼┐ ┌───▼──┐ ┌▼────┐ ┌▼────┐ ┌▼────────────┐
              │Auth Service │ │Core  │ │Logis│ │Curr │ │Notifications │
              │:8080        │ │Inven │ │Opt. │ │ency │ │:9005         │
              │Spring Boot  │ │:8080 │ │:3000│ │:9008│ │NestJS        │
              │Kotlin       │ │KT/SB │ │NestJ│ │NestJ│ │WS + Kafka    │
              └──────┬──────┘ └──┬───┘ └──┬──┘ └──┬──┘ └─────┬────────┘
                     │           │         │        │           │
              ┌──────▼───────────▼─────────▼────────▼───────────▼──────┐
              │                   PostgreSQL 16                          │
              │  erp_auth · erp_inventory · erp_logistics · erp_main    │
              └────────────────────────────────────────────────────────┘
                     │                                          │
              ┌──────▼──────┐                         ┌────────▼───────┐
              │  Redis 7    │                         │  Kafka (KRaft) │
              │  Sessions   │                         │  10 topics     │
              │  Rate Limit │                         │  Event bus     │
              └─────────────┘                         └────────────────┘
```

---

## Módulos y Features Actuales

### 🔐 Autenticación y Usuarios
- Login con usuario/contraseña y Google OAuth2
- JWT firmado RS256 con refresh tokens en Redis
- Roles: `ADMIN`, `CLIENTE`, `BODEGUERO`, `COMERCIAL` + brand functions por marca
- Gestión de usuarios y permisos desde panel admin
- Sincronización cross-tab (login/logout en múltiples pestañas)
- IP throttling y rate limiting en gateway

### 📦 Inventario y Activos
- Catálogo unificado de activos rentables con SKU, niveles (CONJUNTO → PRODUCTO → COMPONENTE → MATERIAL)
- Stock virtual — disponibilidad calculada por rangos de fechas
- BOM (Bill of Materials) para kits y módulos modulares
- Visor 3D de productos (catalog/studio)
- Cuarentena y recepción de activos devueltos
- Etiquetas QR y tracking por serial

### 🏗️ Proyectos y Eventos
- Ciclo de vida completo: DRAFT → CONFIRMED → DISPATCHED → ON_SITE → RETURNING → RETURNED → COMPLETED → CANCELLED
- Booking cart para asignar activos a proyectos
- Constructor visual 2D de planos del evento
- Bitácora completa: cada acción (creación, cambio de estado, emails, confirmaciones) queda registrada en timeline
- Confirmación de órdenes por email con link único de un solo uso (sin auth)
- Soporte para unidades organizativas: `BRANDS` y `ORGS`

### 📊 Estado de Órdenes por Marca
- Cada proyecto puede tener órdenes por marca (CELEBRATE, KEEPME, CUSTOMX, MARKETPLACE)
- Flujo: PENDIENTE → CONFIRMADO → DESPACHADO → LISTO
- Notificación por email con plantilla HTML Quantum (dark theme, barra de progreso)
- Confirmación manual o por link de email
- Validación de departamento configurado antes de crear orden

### 🚚 Logística
- Planificación de despachos con destinos múltiples
- Optimizador 3D de cubing y stacking (NestJS)
- Integración con Lalamove API para costos de flete
- Checklist de carga por despacho
- Módulo Quantum Logistics: pedidos, alistamiento, despacho, recepción, pérdidas, Q-Points, salidas

### 🔧 Mantenimiento
- Cola de mantenimiento con triage workflow
- Reparaciones modulares con historial de costos
- ROI tracking por activo (STAR / DORMANT / COST_DRAIN / REGULAR)
- Registro de daños desde retorno de eventos
- Vista de pérdidas y control de activos dañados

### 📈 Analítica
- Gantt de proyectos por rango de fechas
- Gantt de productos (utilización de activos)
- Revenue view: ingresos por mes, top clientes, análisis de ítems
- Ventas perdidas (lost sales tracker)
- Leaderboard: mejores ítems, mejores clientes, margen neto

### 💼 CRM Comercial
- **Pipeline Kanban**: 6 etapas (Prospecto → Contactado → Propuesta → Negociación → Ganado → Perdido)
- Multi-marca: un deal puede incluir CELEBRATE, KEEPME, CUSTOMX, MARKETPLACE
- Deals con valor COP, probabilidad, fecha de cierre esperada, comercial asignado
- Vinculación CRM → ERP: deals ganados crean proyectos en DRAFT automáticamente
- Gestión de contactos con fuente, tags, historial de proyectos vinculados
- Calendario de actividades con deals por fecha
- Tareas (Tasks) con asignación por usuario, prioridad, fecha límite y estado
- **Gestor CRM (Admin Hub)**: KPIs globales, rendimiento por comercial, unidades organizativas ORGS/BRANDS, drill-down por departamento con ingresos por evento, eventos cerrados, deals perdidos

### 🔔 Notificaciones
- Email transaccional vía Gmail API (service account con domain-wide delegation)
- Plantillas HTML: `project.created`, `order-status-transition`, `project.updated`
- WebSocket gateway para notificaciones in-app en tiempo real
- Push notifications (Firebase)
- Kafka como bus de eventos para todos los tipos de notificación

### 💱 Brandex Currency (BX)
- Wallet de puntos BX por usuario
- Asignación mensual automática (10 BX default)
- Ledger de transacciones
- Rate limiting 100 req/min

### 🏢 Configuración Organizacional
- Gestión de departamentos (brand code, responsables, emails)
- Centros de costo con unidad organizativa (BRANDS / ORGS) y categoría de evento
- Panel de configuración unificado (Settings)

### 👤 Portales por Rol
- **Admin**: Dashboard completo, inventario, proyectos, logística, analítica, CRM Hub, configuración
- **Bodeguero**: Recepción, mantenimiento, proyectos asignados, reporte de pérdidas
- **Cliente**: Portal propio, historial de pedidos, detalle de proyectos
- **Comercial**: CRM pipeline, contactos, calendario, tareas

### 🛍️ Marcas y Catálogos
- **Celebrate**: Catálogo de mobiliario y equipo para eventos
- **KeepMe**: Activaciones de marca, stands, material POP
- **CustomX**: Módulos y construcciones personalizadas
- **Marketplace**: Marketplace unificado (requiere auth)
- **Swag**: Merchandise personalizado con SwagStudio configurador
- **KeepMe Command Center**: Panel admin de la marca
- **Swag Command Center**: Panel admin de swag

---

## Módulos Pendientes / En Construcción

| Módulo | Ubicación | Estado | Descripción |
|--------|-----------|--------|-------------|
| **Tabla Maestra de Costos** | `inventory/CostsPage.tsx` | 🚧 Placeholder | ROI, depreciación, historial de mantenimiento por activo |
| **CRM — Campañas de Email** | `crm/CrmMarketingPage.tsx` | ⚠️ Solo localStorage | Templates de email, segmentación, envíos masivos — sin backend |
| **CRM — Tickets de Soporte** | `crm/CrmServicePage.tsx` | ⚠️ Solo localStorage | Gestión de tickets, SLA, historial — sin backend |
| **CRM — Feed de Actividad** | `CrmActivityPage` | 🚧 Stub | Timeline global de actividad comercial |
| **CRM — Analytics/Reportes** | `CrmAnalyticsPage` | 🚧 Stub | Reportes personalizados, métricas de conversión |
| **CRM — Admin Panel** | `CrmAdminPage` | 🚧 Stub | Configuración CRM, integraciones, exportación, permisos |
| **CRM — Backend completo** | `Backend/core-inventory` | 📋 Parcial | Deals, contactos y tareas del CRM viven en localStorage; necesitan persistencia en DB |
| **Sincronización bidireccional CRM↔ERP** | — | 📋 Pendiente | Sincronizar estado de proyectos ERP de vuelta al pipeline CRM |
| **Notificaciones WhatsApp / Slack** | `Backend/notifications` | 📋 Pendiente | Canales adicionales de notificación |
| **Exportación / Reporting** | — | 📋 Pendiente | Export a PDF, Google Sheets, reportes programados |
| **Módulo Financiero** | — | 📋 Pendiente | Facturación, presupuestos, cotizaciones formales |

---

## Infraestructura

### Servicios Docker

| Servicio | Puerto (host) | Tecnología | Propósito |
|----------|--------------|------------|-----------|
| `erp-gateway` | `:80` | Spring Cloud Gateway | Entry point único, JWT, rate limit |
| `erp-auth` | — (interno) | Spring Boot / Kotlin | IdP custom, OAuth2, refresh tokens |
| `erp-inventory` | — (interno) | Spring Boot / Kotlin | Motor de alquiler, proyectos, logística |
| `erp-logistics` | — (interno) | NestJS | Cubing 3D, flete, Lalamove |
| `erp-currency` | — (interno) | NestJS | Wallet BX, ledger, Kafka consumer |
| `erp-notifications` | `:9005` | NestJS | Email, push, WebSocket, Kafka consumer |
| `erp-postgres` | `:5433` | PostgreSQL 16 | Base de datos principal |
| `erp-redis` | `:6380` | Redis 7 | Sessions, cache, rate limiting |
| `erp-kafka` | `:9095/:9096` | Apache Kafka (KRaft) | Bus de eventos |
| `erp-zipkin` | `:9412` | Zipkin 3 | Trazabilidad distribuida |

### Kafka Topics

| Topic | Particiones | Propósito |
|-------|-------------|-----------|
| `erp.inventory.asset.dispatched` | 3 | Activo despachado a evento |
| `erp.inventory.asset.returned` | 3 | Activo retornado |
| `erp.inventory.asset.damaged` | 3 | Daño reportado |
| `erp.inventory.asset.state-change` | 3 | Cambio de estado de activo |
| `erp.inventory.asset.staged` | 3 | Activo alistado para despacho |
| `erp.asset.budget-variance` | 3 | Varianza presupuestaria |
| `notification.email` | 3 | Solicitud de envío de email |
| `notification.push` | 3 | Solicitud de push notification |
| `notification.inapp` | 3 | Notificación in-app (WebSocket) |
| `user.created` | 3 | Nuevo usuario creado |
| `user.credentials.sent` | 3 | Credenciales enviadas |

### Schemas PostgreSQL

| Schema | Servicio | Propósito |
|--------|----------|-----------|
| `erp_auth` | Auth Service | Usuarios, roles, refresh tokens, OAuth |
| `erp_inventory` | Core Inventory | Activos, proyectos, asignaciones, mantenimiento |
| `erp_logistics` | Logistics Optimizer | Despachos, cubing, costos de flete |
| `erp_main` | Currency, Notifications | Wallet BX, notificaciones, templates |
| `gestion` | Core Inventory | Eventos de proyecto (bitácora), órdenes de marca |
| `mantenimiento` | Core Inventory | Registros de mantenimiento, triaje |
| `almacen` | Core Inventory | Módulos, partes, BOM |
| `sistema` | Core Inventory | Configuración, departamentos |

---

## Tech Stack

| Capa | Tecnología | Versión |
|------|-----------|---------|
| Frontend Framework | React | 18 |
| Build tool | Vite | latest |
| Routing | React Router | v6 |
| State / Cache | Zustand (auth) + TanStack Query | latest |
| Backend JVM | Spring Boot + Kotlin | 3.3.x / 2.x |
| Backend Node | NestJS + TypeScript | 10–11 |
| API Gateway | Spring Cloud Gateway (WebFlux) | latest |
| Base de datos | PostgreSQL | 16 |
| Message broker | Apache Kafka (KRaft) | latest |
| Cache / Sessions | Redis | 7 |
| ORM (JVM) | Spring Data JPA / Hibernate | latest |
| ORM (Node) | TypeORM | latest |
| Auth | JWT RS256 + OAuth2 Google | — |
| Observabilidad | Zipkin + Micrometer + Prometheus | 3.x |
| Contenerización | Docker + Docker Compose | latest |
| CI/CD | GitHub Actions (pendiente configurar) | — |

---

## Flujo de Trabajo — GitHub Flow

Este proyecto sigue **GitHub Flow**: rama principal protegida, ramas de feature cortas, Pull Requests obligatorios.

### Reglas de la rama `main`

- `main` es siempre **deployable** — nunca se hace push directo
- Solo el **líder de desarrollo** puede aprobar y hacer merge de PRs
- Toda integración pasa por PR con al menos **1 aprobación**
- Los PRs deben pasar los checks de CI antes de poder mergear (cuando CI esté configurado)

### Ciclo de vida de un feature

```
main
 │
 ├── git checkout -b feat/nombre-descriptivo    ← 1. Crear rama desde main actualizado
 │
 │   [desarrollo + commits atómicos]             ← 2. Desarrollar en la rama
 │
 ├── git push origin feat/nombre-descriptivo     ← 3. Push al remoto
 │
 ├── [Abrir Pull Request → main]                 ← 4. PR con descripción y contexto
 │
 ├── [Code Review por el líder]                  ← 5. Review: aprobar o pedir cambios
 │
 └── [Merge Squash a main]                       ← 6. Merge limpio, rama eliminada
```

### Convenciones de nombres de ramas

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `feat/` | Nueva funcionalidad | `feat/crm-backend-deals` |
| `fix/` | Corrección de bug | `fix/order-confirmation-404` |
| `refactor/` | Refactoring sin cambio de comportamiento | `refactor/inventory-service-split` |
| `chore/` | Infraestructura, dependencias, config | `chore/kafka-topics-init` |
| `docs/` | Solo documentación | `docs/api-endpoints` |

### Convenciones de commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(crm): add deals backend persistence
fix(gateway): bypass JWT for confirm token endpoint
refactor(inventory): extract order status service
chore(infra): add kafka topic for budget variance
docs(readme): add github flow section
```

### Descripción del PR (template sugerido)

```markdown
## ¿Qué hace este PR?
Descripción breve del cambio.

## ¿Por qué?
Contexto o ticket que lo origina.

## Cambios relevantes
- Archivo A: ...
- Archivo B: ...

## Testing
- [ ] Probado localmente
- [ ] No rompe funcionalidad existente
- [ ] Variables de entorno documentadas si aplica
```

---

## Roles del Equipo

### 👑 Líder de Desarrollo — Full Stack

**Responsabilidades:**
- Arquitectura general del sistema (microservicios, contratos de API, modelo de datos)
- Revisión y aprobación de **todos los Pull Requests** antes de merge a `main`
- Decisiones de tecnología y patrones de código
- Resolución de conflictos de integración entre servicios
- Configuración de infraestructura (Docker, Kafka, PostgreSQL schemas, Gateway routes)
- Features críticos de seguridad (Auth Service, JWT, Gateway filters)
- Mantenimiento del `main` branch y releases

**Cómo trabajar con el líder:**
- Abrir PR con descripción clara — nunca pedir merge verbal
- Si un PR lleva más de 48h sin revisión, mencionarlo en el canal del equipo
- No hacer merge sin aprobación explícita, aunque el PR sea pequeño

---

### 🔧 Backend Developer 1 — Core Inventory & Business Logic

**Stack principal:** Kotlin · Spring Boot · JPA · Flyway · PostgreSQL

**Ownership:**
- `Backend/core-inventory` — toda la lógica de negocio del motor de alquiler
- Entidades: `ProjectBrandOrder`, `ProjectEvent`, `Department`, `CostCenter`, `InventoryItem`, `Assignment`
- Servicios: `OrderStatusService`, `EventBookingService`, `MaintenanceService`, `AnalyticsService`
- Migraciones Flyway de los schemas `erp_inventory`, `gestion`, `mantenimiento`, `almacen`, `sistema`
- Endpoints REST del inventario, proyectos, mantenimiento, analítica
- Integración con servicio de notificaciones (NotificationClient)
- Validaciones de negocio (stock virtual, validación de departamentos, transiciones de estado)

**Coordinación:**
- Comunicar cambios de schema al líder antes de crear migración
- Definir contratos de API con Frontend via comentarios en el PR o especificación OpenAPI
- Avisar cuando un endpoint cambia firma para que Frontend actualice su cliente

---

### 🔧 Backend Developer 2 — Services & Infrastructure

**Stack principal:** NestJS · TypeScript · Kafka · Redis · PostgreSQL · Docker

**Ownership:**
- `Backend/auth-service` — IdP, JWT, OAuth2, refresh tokens, gestión de usuarios
- `Backend/notifications` — email (Gmail API), push (Firebase), WebSocket, Kafka consumers, plantillas HTML
- `Backend/logistics-optimizer` — cubing 3D, stacking, integración Lalamove
- `Backend/currency` — wallet BX, ledger de transacciones, asignación mensual
- `Backend/gateway` — rutas, JWT validation filter, rate limiting, circuit breaker
- `Backend/infra` — Docker Compose, scripts de init (Kafka topics, PostgreSQL schemas), secrets
- Migraciones de `erp_auth`, `erp_main`, `erp_logistics`
- Nuevos canales de notificación (WhatsApp, Slack — pendiente)

**Coordinación:**
- Cuando se agrega un nuevo endpoint público, coordinar con el líder para agregar a bypass list del gateway si es necesario
- Cambios en el formato de emails o plantillas HTML → PR pequeño y descriptivo
- Variables de entorno nuevas → documentar en `.env.example` del servicio correspondiente y actualizar esta sección del README

---

### 🎨 Frontend Developer — React & UX

**Stack principal:** React 18 · TypeScript · Vite · React Router v6 · TanStack Query · Zustand · Tailwind

**Ownership:**
- `Frontend/src/` — todas las páginas, componentes, layouts, hooks, utilidades
- Sistema de diseño Quantum (dark theme, variables CSS, componentes reutilizables)
- Integración con todos los endpoints del backend via `apiClient`
- Flujo de autenticación frontend (AuthStore, ProtectedRoute, cross-tab sync)
- CRM completo (pipeline, contactos, calendario, tareas, CRM Hub)
- Páginas de catálogo público (Celebrate, KeepMe, CustomX, Marketplace, Swag)
- Portales por rol (Admin, Bodeguero, Cliente, Comercial)
- Formateo de moneda COP en todo el sistema (`es-CO` locale)

**Coordinación:**
- Cuando el backend expone un endpoint nuevo, pedir la firma exacta (DTO, ruta, método) antes de implementar
- PRs de frontend separados de PRs de backend — no mezclar en el mismo PR
- Páginas placeholder marcadas como `🚧` se pueden completar en PRs independientes
- Módulos CRM pendientes de backend: implementar UI primero con mock/localStorage, luego conectar cuando el backend esté listo

---

## Setup Local

### Prerrequisitos

- Docker Desktop (Windows/Mac) o Docker Engine (Linux)
- Node.js 20+ y pnpm/npm
- Java 21+ (solo si se corre backend fuera de Docker)

### 1. Levantar infraestructura

```bash
cd Backend/infra
cp .env.example .env          # configurar variables
docker compose up -d          # levanta todos los servicios
```

Los servicios tardan ~60s en estar healthy (PostgreSQL, Kafka, Redis primero, luego los demás).

Verificar que todos estén corriendo:
```bash
docker compose ps
# Todos los servicios deben mostrar "healthy" o "running"
```

### 2. Levantar el Frontend

```bash
cd Frontend
cp .env.example .env.local    # configurar VITE_GATEWAY_URL
npm install
npm run dev                   # http://localhost:5173
```

### 3. Acceso por defecto

| Servicio | URL | Credenciales default |
|----------|-----|---------------------|
| Frontend | `http://localhost:5173` | Crear usuario en `/dashboard/users` |
| API Gateway | `http://localhost:80` | — |
| Zipkin | `http://localhost:9412` | — |
| Swagger (core-inventory) | `http://localhost:80/swagger-ui.html` | — |

---

## Variables de Entorno

### Frontend (`.env.local`)

```env
VITE_GATEWAY_URL=http://localhost:80
VITE_GOOGLE_CLIENT_ID=<google-oauth-client-id>
```

### Notifications Service (`.env`)

```env
NODE_ENV=development
PORT=9005
DB_HOST=erp-postgres
DB_PORT=5432
DB_NAME=erp_main
DB_USER=erp
DB_PASSWORD=<ver Backend/infra/.env>
KAFKA_BROKERS=erp-kafka:9095
KAFKA_CLIENT_ID=notifications-service
KAFKA_GROUP_ID=notifications-group
REDIS_HOST=erp-redis
REDIS_PORT=6379
GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/google-sa.json
GMAIL_SEND_AS=eventos@brandex.global
GMAIL_FROM_NAME=Quantum · Brandex
INTERNAL_API_KEY=<clave-compartida-con-core-inventory>
```

### Currency Service (`.env`)

```env
NODE_ENV=development
PORT=9008
DB_HOST=erp-postgres
KAFKA_BROKERS=erp-kafka:9095
MONTHLY_BX_ALLOCATION=10
JWT_PUBLIC_KEY=<public key del auth-service>
```

### Secretos (no versionados)

- `Backend/infra/secrets/auth_rsa.pem` — clave privada RS256 del IdP
- `Backend/infra/secrets/auth_rsa.pub.pem` — clave pública RS256
- `Backend/infra/secrets/google-sa.json` — service account GCP para Gmail API

> ⚠️ Ningún archivo de `secrets/` debe committearse. Están en `.gitignore`.

---

*Quantum ERP — Brandex Global · Sistema interno · No distribuir*
