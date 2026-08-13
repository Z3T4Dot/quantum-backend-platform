# Quantum ERP — Architecture Blueprint

**Versión:** 3.3  
**Fecha:** 2026-08-04  
**Estado:** Documento oficial de arquitectura  
**Clasificación:** Referencia técnica interna — Brandex Global

---

## Índice

**PARTE I — EL SISTEMA**
1. [Filosofía del Sistema](#1-filosofía-del-sistema)
2. [Modelo Operacional de Brandex](#2-modelo-operacional-de-brandex)
3. [Principios Arquitectónicos](#3-principios-arquitectónicos)
   - [P-DOM-001 — Propiedad exclusiva del modelo de datos](#p-dom-001--propiedad-exclusiva-del-modelo-de-datos)
   - [P-SEC-001 — Autorización siempre desde la fuente de verdad](#p-sec-001--autorización-siempre-desde-la-fuente-de-verdad)
   - [P-SEC-002 — Autenticación de servicio a servicio](#p-sec-002--autenticación-de-servicio-a-servicio)
   - [P-ENG — Business Engine Architecture](#p-eng--business-engine-architecture)
     - [P-ENG-001 — Abstracción de Motores de Negocio](#p-eng-001--abstracción-de-motores-de-negocio)
     - [P-ENG-002 — Catálogo de Capacidades](#p-eng-002--catálogo-de-capacidades)
     - [P-ENG-003 — Business Contracts](#p-eng-003--business-contracts)
     - [P-ENG-004 — Business Blueprints](#p-eng-004--business-blueprints)
     - [P-ENG-005 — Business Runtime](#p-eng-005--business-runtime)
     - [P-ENG-006 — Módulos como Artefactos Controlados](#p-eng-006--módulos-como-artefactos-controlados)
     - [P-ENG-007 — Business Journeys *(deferred)*](#p-eng-007--business-journeys-deferred)
   - [P-ARC — Platform Architecture Constraints](#p-arc--platform-architecture-constraints)
     - [P-ARC-001 — Anti-Complejidad](#p-arc-001--anti-complejidad)
     - [P-ARC-002 — Dominio-Ignorante](#p-arc-002--dominio-ignorante)
   - [P-CLS — Taxonomía de Servicios de Quantum](#p-cls--taxonomía-de-servicios-de-quantum)
     - [Reglas de dependencia entre capas (P-CLS)](#reglas-de-dependencia-entre-capas-p-cls)
   - [P-PLT — Platform Service Architecture](#p-plt--platform-service-architecture)
     - [P-PLT-001 — Zero Trust Interno](#p-plt-001--zero-trust-interno)
     - [P-PLT-002 — Stateless por Diseño](#p-plt-002--stateless-por-diseño)
     - [P-PLT-003 — Identidad de Servicio](#p-plt-003--identidad-de-servicio)
     - [P-PLT-004 — Plataforma Opaca al Dominio](#p-plt-004--plataforma-opaca-al-dominio)
     - [P-PLT-005 — Alta Disponibilidad No Negociable](#p-plt-005--alta-disponibilidad-no-negociable)
   - [P-FND — Foundation Service Architecture](#p-fnd--foundation-service-architecture)
     - [P-FND-001 — Dominio Transversal](#p-fnd-001--dominio-transversal)
     - [P-FND-002 — API como Contrato Estable](#p-fnd-002--api-como-contrato-estable)
     - [P-FND-003 — Sin Lógica de Engine](#p-fnd-003--sin-lógica-de-engine)
     - [P-FND-004 — Consumible por Cualquier Engine](#p-fnd-004--consumible-por-cualquier-engine)

**PARTE II — EL DOMINIO**
4. [Modelo de Dominio](#4-modelo-de-dominio)
5. [Bounded Contexts y Context Map](#5-bounded-contexts-y-context-map)
6. [El Proyecto como Aggregate Root](#6-el-proyecto-como-aggregate-root)
7. [Ownership Matrix](#7-ownership-matrix)

**PARTE III — LOS EVENTOS**
8. [Domain Events](#8-domain-events)

**PARTE IV — EL JOURNEY**
9. [Journey de un Proyecto](#9-journey-de-un-proyecto)

**PARTE V — LA ARQUITECTURA TÉCNICA**
10. [Diagnóstico de la Arquitectura Actual](#10-diagnóstico-de-la-arquitectura-actual)
11. [Catálogo de Servicios](#11-catálogo-de-servicios)
12. [Arquitectura de Datos](#12-arquitectura-de-datos)
13. [Comunicación entre Servicios](#13-comunicación-entre-servicios)
14. [Estándares de API](#14-estándares-de-api)

**PARTE VI — LA PLATAFORMA**
15. [Arquitectura del Frontend](#15-arquitectura-del-frontend)
16. [Infraestructura y Despliegue](#16-infraestructura-y-despliegue)
17. [Seguridad](#17-seguridad)
18. [Observabilidad](#18-observabilidad)

**PARTE VII — DECISIONES Y FUTURO**
19. [Decisiones Arquitectónicas (ADRs)](#19-decisiones-arquitectónicas-adrs)
20. [Hoja de Ruta de Migración](#20-hoja-de-ruta-de-migración)
21. [Riesgos y Mitigaciones](#21-riesgos-y-mitigaciones)

**DOCUMENTOS COMPLEMENTARIOS**
- [BUSINESS_ENGINES_CATALOG.md](BUSINESS_ENGINES_CATALOG.md) — Catálogo formal de Engines, Capabilities, Contracts, Blueprints y Módulos
- [BUSINESS_BLUEPRINT_SPEC.md](BUSINESS_BLUEPRINT_SPEC.md) — Lenguaje oficial de declaración de módulos (schema + ejemplos completos + reglas de validación)
- [PLATFORM_RUNTIME_DESIGN.md](PLATFORM_RUNTIME_DESIGN.md) — Diseño técnico del Platform Runtime: 8 componentes, Platform.start(), Engine Dispatcher, Module Installer

---

# PARTE I — EL SISTEMA

---

## 1. Filosofía del Sistema

### Quantum ERP no es software. Es el sistema operativo de Brandex.

Un ERP genérico asume que cualquier empresa puede adaptarse a sus procesos. SAP, Odoo y Dynamics están construidos sobre ese supuesto. Brandex no es cualquier empresa. Brandex produce experiencias: eventos corporativos, instalaciones de marca, activaciones, experiencias de campo. Su operación es creativa, dinámica y orientada a proyectos únicos. Ningún ERP de mercado modela correctamente esa realidad.

Quantum ERP nace de una pregunta diferente: ¿cómo se digitalizan exactamente las operaciones de Brandex, sin compromisos, sin adaptaciones artificiales, sin que el software obligue al negocio a cambiar su manera de operar?

La respuesta a esa pregunta es este sistema.

### Qué problema resuelve

Brandex opera con múltiples departamentos que trabajan en simultáneo sobre los mismos proyectos, con activos físicos compartidos, con proveedores externos, con clientes que necesitan visibilidad, y con presupuestos que se deben controlar en tiempo real. Hasta ahora, esa coordinación ocurre a través de emails, hojas de cálculo, mensajes de WhatsApp y conversaciones informales. El conocimiento sobre un proyecto vive en la cabeza de las personas, no en el sistema.

Quantum ERP resuelve ese problema: centraliza el conocimiento operacional en una única fuente de verdad, coordina los flujos entre departamentos, y da visibilidad completa sobre el estado de cada proyecto en cada momento.

### Single Source of Truth

Cada dato del negocio tiene un único lugar donde vive. No existe la misma información en dos lugares distintos. Cuando el estado de un proyecto cambia, ese cambio es visible de inmediato para todos los departamentos. Cuando un activo es reservado, nadie más puede reservarlo. Cuando una factura es generada, el sistema sabe exactamente qué costos la componen.

Single Source of Truth no es un principio técnico. Es un compromiso con la realidad operacional de la empresa.

### Por qué no buscamos un ERP genérico

Los ERP genéricos modelan procesos estándar de industria. Brandex tiene procesos propios que no tienen equivalente estándar: el ciclo de vida de un proyecto de producción de eventos no es igual al de un proyecto de manufactura, ni al de un proyecto de consultoría. La ficha de un activo como una cabina de DJ no es igual a la de un inventario de repuestos industriales. El flujo de aprobación creativa de un concepto de activación no existe en ningún módulo de SAP.

Cualquier intento de usar un ERP genérico termina en personalizaciones costosas que crean deuda técnica inmediata. Quantum ERP está construido desde cero sobre el modelo real del negocio de Brandex.

### Los negocios no se programan: se ensamblan

Los ERP tradicionales dicen: "tengo módulos — Compras, Ventas, Inventario, RRHH. Elige los que necesitas."

Quantum dice algo distinto: **tengo motores operacionales. Los negocios se construyen ensamblando esos motores.**

Un nuevo departamento, una nueva línea de negocio, un nuevo modelo operacional — ninguno de esos cambios implica escribir un nuevo microservicio. Implica declarar un Business Blueprint: qué Engines se usan, qué capacidades se activan, qué workflows se definen. El Business Runtime interpreta esa declaración y construye el pipeline. El código no cambia.

Esto transforma radicalmente la naturaleza del crecimiento de la plataforma:

- **Crecimiento operacional** — un nuevo módulo es una declaración YAML. No hay Java, no hay Spring, no hay deploy de nuevo código.
- **Crecimiento de capacidades** — cuando un dominio requiere algo que ningún Engine ofrece, se amplía el Engine existente o se crea uno nuevo. Ese trabajo es de plataforma, no de producto.
- **Crecimiento de escala** — los Engines son independientes entre sí. Escalan horizontalmente sin que los módulos se enteren.

Esta distinción es la que separa a Quantum de cualquier ERP del mercado. No es un sistema con módulos. Es una plataforma de ejecución de negocios donde los módulos son configuraciones declarativas de motores reutilizables.

### Los Blueprints como activo principal del producto

En la mayoría de las plataformas de software, el código es el activo. En Quantum, el activo principal son los **Business Blueprints**.

Un Blueprint describe cómo se construye una solución de negocio: qué Engines se usan, qué Capabilities se activan, qué workflows se definen, qué eventos se publican y consumen. Ese Blueprint puede versionarse, auditarse, revertirse y reutilizarse. El Engine que lo ejecuta es intercambiable — lo que perdura es la descripción del negocio.

Esto tiene cuatro implicaciones directas:

- **Los Engines evolucionan lentamente** — son infraestructura de negocio, no código de producto. Cada nuevo Engine es una inversión de largo plazo.
- **Los Business Contracts estabilizan la interfaz** — la línea entre plataforma y negocio es explícita, versionada e inmutable en cada versión.
- **Los Blueprints son el activo de producto** — cuando alguien quiere entender cómo funciona KeepMe o Celebrate, lee el Blueprint, no el código.
- **El Runtime es el sistema operativo de Quantum** — interpreta los Blueprints, hace cumplir los contratos y convierte la declaración en comportamiento. Es el único componente que conoce la plataforma completa.

Si se mantiene esa disciplina — Engine → Contract → Blueprint → Runtime — el crecimiento futuro de Quantum no dependerá principalmente de escribir más código, sino de enriquecer el catálogo de Capabilities y de componerlas de formas nuevas. Esa es una propiedad que pocas plataformas consiguen.

### La hipótesis que debe convertirse en hecho

"Los negocios no se programan: se ensamblan" es hoy una hipótesis arquitectónica, no un hecho demostrado. Es una hipótesis muy bien fundamentada — pero sigue siendo una hipótesis hasta que cuatro casos concretos funcionen en producción.

Los cuatro casos que la convierten en hecho:

| Caso | Condición de validación |
|------|------------------------|
| **KeepMe** | Se declara únicamente mediante un Blueprint. No existe ni una línea de código Java específica de KeepMe. |
| **Celebrate** | Se declara sin modificar Inventory Engine. El Engine no sabe que Celebrate existe. |
| **SWAG** | Combina tres Engines (Inventory + Creative + Manufacturing) sin que exista ninguna dependencia directa entre ellos. |
| **Ningún Engine** | Contiene lógica condicional basada en el nombre del módulo que lo usa. |

Hasta que los cuatro funcionen: hipótesis prometedora.

Cuando los cuatro funcionen: verdad arquitectónica demostrable, auditable y reproducible.

> Esta distinción importa. Construir sobre una hipótesis no verificada es razonable mientras el equipo es consciente de que lo es. Confundir la hipótesis con un hecho lleva a decisiones que no se cuestionan cuando deberían cuestionarse.

### Construido para durar

La arquitectura de este sistema está diseñada para que, si Brandex duplica su tamaño, abre nuevas líneas de negocio o incorpora nuevos departamentos, la evolución consista principalmente en extender dominios existentes, no en rediseñar la arquitectura. Los departamentos organizacionales pueden cambiar. Los dominios del negocio permanecen.

Si Brandex abre una nueva línea de negocio mañana, ese cambio se manifiesta como una nueva configuración del sistema, no como una reescritura.

### Principio rector

> La arquitectura debe ser una representación del negocio, no al revés. Toda decisión técnica que no esté motivada por una necesidad operacional real debe ser cuestionada.

---

## 2. Modelo Operacional de Brandex

Este capítulo describe cómo funciona realmente el negocio, independientemente de la tecnología. Es la base sobre la cual se construye el dominio.

### El flujo completo de un evento

```
  COMERCIAL          DISEÑO            PRODUCCIÓN           OPERACIONES         CIERRE
  ─────────          ──────            ──────────           ───────────         ──────
  
  Lead               Brief             Plan de              Logística           Retorno
  Calificación    →  Concepto      →   producción        →  pre-evento       →  Inventario
  Propuesta          Aprobación        Fabricación           Evento              Mantenimiento
  Negociación        creativa          Reserva de            Setup               Reconciliación
  Deal WON           ──────────        activos               Tear-down           Facturación
  ──────────         ↓                 Marketplace           ──────────          Analytics
  ↓                  Proyecto          ──────────            ↓                   ──────────
  Proyecto           confirmado        ↓                     Proyecto            ↓
  creado                               Proyecto en           en ejecución        Proyecto
                                       producción                                cerrado
```

### Actores del sistema

**Actores internos (usuarios de Brandex):**

| Actor | Rol en el sistema |
|---|---|
| Director Comercial | Gestiona el pipeline, aprueba propuestas |
| Asesor Comercial | Crea y sigue leads, gestiona relación con el cliente |
| Coordinador de Proyectos | Administra la ficha del proyecto, coordina entre departamentos |
| Líder de Departamento | Recibe proyectos asignados, crea y ejecuta órdenes de trabajo |
| Operador de Bodega | Gestiona inventario físico, despacha y recibe activos |
| Equipo Creativo | Desarrolla conceptos, sube entregables creativos |
| Proveedor de Marketplace | Contrata recursos externos para proyectos |
| Analista | Consulta reportes, KPIs y analytics |
| Administrador del sistema | Configura departamentos, estados, permisos |

**Actores externos:**

| Actor | Interacción |
|---|---|
| Cliente | Recibe propuestas, aprueba creativos, recibe facturas |
| Proveedor / Vendor | Recibe órdenes de compra, confirma entregas |

### Glosario operacional

Antes de cualquier decisión de dominio, es necesario acordar el significado de las palabras del negocio:

| Término | Definición en Brandex |
|---|---|
| **Lead** | Oportunidad comercial en etapa de exploración, antes de comprometerse a una propuesta formal |
| **Deal** | Oportunidad en etapa avanzada, con propuesta enviada y negociación activa |
| **Brief** | Documento de requisitos del cliente para un evento o proyecto |
| **Proyecto** | La entidad central del sistema. Agrupa todo el trabajo necesario para ejecutar un evento o experiencia |
| **Ficha Maestra** | Vista unificada del proyecto que consolida información de todos los departamentos |
| **Orden de Trabajo** | Solicitud de un departamento específico para ejecutar su parte dentro de un proyecto |
| **Activo** | Elemento físico propiedad de Brandex (estructura, pantalla, mueble, vehículo, etc.) |
| **Entidad Dinámica** | Elemento catalogado con atributos variables (vehículo, speaker, venue, consumible) |
| **Recurso Externo** | Servicio o bien contratado a un proveedor para un proyecto específico |
| **Dispatch** | Operación de transporte y entrega de activos hacia o desde un punto de evento |
| **Marketplace** | El proceso de identificar, contratar y gestionar proveedores externos para proyectos |

### Las cuatro fases del ciclo de vida de un proyecto

Independientemente de cuántos estados tenga un proyecto, todo su ciclo de vida pertenece a una de cuatro fases:

**FASE 1 — EXPLORACIÓN**
Desde que nace el lead hasta que el proyecto es oficialmente aprobado y comprometido. Es el dominio del CRM y el equipo comercial.

**FASE 2 — APROBACIÓN**
Desde que el proyecto es confirmado hasta que el concepto creativo es aprobado por el cliente. Es el dominio del equipo creativo y la coordinación. Ningún recurso se reserva hasta que esta fase termina.

**FASE 3 — EJECUCIÓN**
Desde la aprobación creativa hasta el cierre del evento. Comprende producción, logística, evento y retorno. Es el dominio de todos los departamentos operativos.

**FASE 4 — CIERRE**
Desde el retorno de activos hasta la liquidación financiera y el análisis. Es el dominio de finanzas y analytics.

---

## 3. Principios Arquitectónicos

Estos principios son no negociables. Toda decisión de diseño que los viole requiere un ADR que justifique la excepción.

### P1 — El dominio primero, la tecnología después

Ninguna decisión de arquitectura técnica existe sin una justificación en el negocio. Si no hay una necesidad operacional real que motive la decisión, la decisión no se toma. Tres microservicios son mejor que doce si el negocio no justifica doce.

### P2 — Single Source of Truth

Cada dato del negocio tiene exactamente un servicio propietario. Ningún otro servicio almacena una copia de ese dato como fuente de verdad. La colaboración entre servicios ocurre a través de APIs y eventos, nunca a través de bases de datos compartidas.

### P3 — Dominios, no departamentos

Los microservicios representan bounded contexts del dominio del negocio. No representan departamentos organizacionales. Los departamentos cambian con el organigrama. Los dominios permanecen mientras la operación exista. Un nuevo departamento no implica un nuevo microservicio.

### P4 — El Proyecto es el centro

Todo el sistema orbita alrededor del Proyecto. El Proyecto es el Aggregate Root del dominio. Todo lo que el CRM hace, crea un Proyecto. Todo lo que los departamentos operativos hacen, se hace para un Proyecto. Todo lo que Analytics mide, lo mide sobre un Proyecto.

### P5 — Falla aislada

Un servicio auxiliar que falla no detiene las operaciones críticas. El equipo de campo debe poder operar aunque Analytics, Notifications o el CRM estén caídos. La disponibilidad de las operaciones de campo es el requisito de resiliencia más importante del sistema.

### P6 — Configuración sobre código para lo que cambia

Lo que el negocio modifica frecuentemente (estados de proyecto, departamentos activos, campos de entidades, módulos habilitados) vive en base de datos. Agregar un nuevo estado de proyecto no requiere un deploy. Lo que define el comportamiento crítico del sistema (validaciones, transacciones, reglas de negocio) vive en código.

### P7 — API-first

Toda funcionalidad existe como API documentada antes de que el frontend la consuma. El contrato de la API es la fuente de verdad, no la implementación.

### P8 — Observabilidad por defecto

Todo servicio emite logs, métricas y trazas desde el primer día. La observabilidad no se añade después. Un sistema que no puede ser monitoreado no puede ser operado en producción.

### P9 — Seguridad en profundidad

La autenticación ocurre en el Gateway. La autorización ocurre en cada servicio. Un servicio nunca confía ciegamente en que el Gateway ya verificó todo lo necesario para ejecutar esa operación específica.

### P-DOM-001 — Propiedad exclusiva del modelo de datos

Cada microservicio es el único propietario de su modelo de datos. Ningún servicio puede leer ni escribir directamente sobre la base de datos de otro servicio. Toda modificación de datos en un dominio ajeno ocurre mediante API REST síncrona o evento de dominio — nunca mediante SQL compartido, acceso directo a la BD, o importación de entidades JPA de otro servicio.

> Este principio se viola frecuentemente con el argumento de que "es solo un UPDATE rápido". Esa excepción destruye la independencia de los bounded contexts. No existe el UPDATE rápido entre servicios.

### P-SEC-001 — Autorización siempre desde la fuente de verdad

Ningún dato de autorización (roles, permisos, scopes, departamentos o privilegios) será considerado fuente de verdad si proviene del cliente o de un JWT. El JWT únicamente acredita la identidad del usuario (`sub`) y la validez de su sesión (`sid`). La autorización siempre se resuelve contra `identity-service`, con Redis como caché distribuida de corta duración.

Corolario: un cambio de rol tiene efecto en la siguiente petición del usuario, sin forzar logout ni esperar la expiración del access token.

### P-SEC-002 — Autenticación de servicio a servicio

Ningún microservicio puede consumir endpoints internos de otro servicio utilizando únicamente una clave compartida (`X-Internal-Key`). Cada microservicio tiene una identidad propia registrada en `identity-service`. La autenticación entre servicios se realiza mediante Service JWTs de corta duración (TTL: 1 hora) firmados con la clave RSA de la plataforma. Si una credencial de servicio se compromete, se revoca únicamente ese servicio — el resto de la plataforma no se ve afectado.

### P-ENG — Business Engine Architecture

Seis principios que forman una narrativa progresiva. Los cinco primeros están activos; el sexto está deferred hasta que existan al menos dos Engines en producción con procesos de negocio que los crucen.

```
Business Engine          P-ENG-001 — implementa la lógica operacional
      ↓
  Capabilities           P-ENG-002 — catálogo de lo que el Engine sabe hacer
      ↓
Business Contract        P-ENG-003 — interfaz estable que expone Capabilities
      ↓
Business Blueprint       P-ENG-004 — composición declarativa de Contracts
      ↓
Business Runtime         P-ENG-005 — lee config, valida deps, construye pipeline
      ↓
Module Configuration
      ↓
Business Module

─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ (horizonte) ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─

Business Journey         P-ENG-006 — orquestación de procesos que cruzan Engines
      ↑ coordina
Business Module A  →  Engine A  →  Engine B  →  Engine C  → Business Module Z
```

---

#### P-ENG-001 — Abstracción de Motores de Negocio

Responde: **¿cómo está organizada la plataforma?**

Los **Business Engines** implementan comportamiento operacional genérico y reutilizable. Nunca contienen lógica específica de un módulo, departamento o unidad de negocio.

Los **Business Modules** son configuraciones concretas de un Engine para un dominio específico. La diferencia entre módulos es de configuración, workflows y metadatos — nunca de código diferenciado dentro del Engine.

| Engine | Comportamiento operacional que implementa |
|--------|-------------------------------------------|
| `inventory-service` | Gestión de activos físicos, cantidades, ubicaciones, trazabilidad |
| `manufacturing-service` | Producción, BOMs, órdenes de trabajo, ensamblaje |
| `creative-service` | Workflows de contenido, aprobaciones, entregables creativos |
| `service-service` | Prestación de servicios, asignación de personas, ejecución en campo |

**Corolario:** un departamento nuevo no implica un nuevo servicio. Si comparte el comportamiento operacional de un Engine existente, se registra como una nueva configuración de ese Engine. El departamento de Renta de Equipo no requiere un `rental-service` propio — es una configuración del Inventory Engine.

> Quantum no escala multiplicando microservicios. Escala ampliando el alcance de sus Engines. Una arquitectura que puede crecer durante años sin crecer en complejidad estructural.

---

#### P-ENG-002 — Catálogo de Capacidades

Responde: **¿qué ofrece un Engine?**

Cada Business Engine implementa un catálogo de capacidades operacionales reutilizables. Un módulo selecciona únicamente las capacidades que necesita; las que no selecciona no existen en su contexto. El Engine no contiene bifurcaciones basadas en qué módulo lo consume.

**Ejemplo — Inventory Engine:**

```
Capacidades disponibles:

  ✓ Asset Registry      ✓ Assignment          ✓ Transfer
  ✓ Reservation         ✓ Inspection          ✓ Maintenance
  ✓ Lifecycle Tracking  ✓ Barcode / QR        ✓ RFID
  ✓ Kits                ✓ Batch Operations    ✓ Audit Trail
```

Capacidades seleccionadas por módulo:

| Capacidad | KeepMe | Celebrate | CustomX |
|-----------|:------:|:---------:|:-------:|
| Asset Registry | ✓ | ✓ | ✓ |
| Transfer | ✓ | ✓ | ✓ |
| Reservation | | ✓ | ✓ |
| Maintenance | | | ✓ |
| Inspection | ✓ | | ✓ |
| QR / Barcode | ✓ | | |
| Kits | ✓ | | |
| Audit Trail | ✓ | | ✓ |

El código del Engine es idéntico para los tres módulos. Lo único que varía es la selección de capacidades.

**Corolario:** nunca se crearán bifurcaciones (`if`, `switch`) basadas en el nombre del módulo dentro de un Engine. Si dos módulos necesitan comportamientos genuinamente distintos para la misma capacidad, ese es el indicador de que se trata de dos capacidades diferentes — no de una capacidad con casos especiales.

---

#### P-ENG-003 — Business Contracts

Responde: **¿cómo consume un módulo esas capacidades?**

Las Capabilities de un Engine no se consumen directamente. Se accede a ellas mediante un **Business Contract** — la interfaz estable y versionada que el Engine publica formalmente. Esta distinción es crítica: el contrato no *es* la capacidad, el contrato *expone* la capacidad. La lógica no vive en el contrato; vive en el Engine.

**Jerarquía completa:**

```
Business Engine          — implementa la lógica operacional
      ↓
  Capabilities           — lo que el Engine sabe hacer
      ↓
Business Contract        — interfaz estable que expone esas Capabilities
      ↓
Module Configuration     — qué Capabilities selecciona este módulo y cómo las configura
      ↓
Business Module (Runtime)
```

Cuatro capas, cuatro responsabilidades sin ambigüedad:

| Capa | Qué representa | Quién la define |
|------|----------------|-----------------|
| **Business Engine** | La lógica operacional reutilizable | Equipo de plataforma |
| **Capabilities** | El catálogo de lo que el Engine puede hacer | Equipo de plataforma |
| **Business Contract** | La interfaz estable que expone esas Capabilities, versionada | Equipo de plataforma |
| **Business Module** | La selección y configuración de Capabilities para un dominio específico | Equipo de producto |

**Analogía:**

```
Motor (Engine)
  ↓
Especificaciones técnicas del pistón (Capabilities)
  ↓
Contrato del pistón — interfaz pública, versionada (Contract)
  ↓
Pistón A    Pistón B    Pistón C (Module Configurations)
  ↓
Automóvil (Runtime)
```

El motor nunca pregunta: ¿eres Ferrari? ¿eres Toyota?  
Pregunta únicamente: ¿cumples el contrato del pistón?  
Si la respuesta es sí — funciona.

**Ejemplo — Inventory Engine:**

```
Inventory Engine
  ↓
Capabilities: ASSET_REGISTRY, TRANSFER, RESERVATION, INSPECTION,
              MAINTENANCE, QR_BARCODE, RFID, KITS, AUDIT_TRAIL ...
  ↓
Inventory Contract v1  ← expone el subconjunto estable de Capabilities
  ↓
KeepMe Config      Celebrate Config      CustomX Config
  ↓
Runtime  (misma implementación, distintas Capabilities seleccionadas)
```

**Corolarios:**

1. Un módulo consume contratos, no implementaciones — nunca accede directamente al Engine.
2. Un contrato expone Capabilities; no puede exponer comportamiento que el Engine no implementa.
3. Un contrato es reutilizable entre múltiples módulos del mismo Engine.
4. Las diferencias entre módulos se expresan en qué Capabilities seleccionan y cómo las configuran — nunca en código diferenciado dentro del Engine.
5. La evolución del Engine mantiene compatibilidad hacia atrás con contratos existentes; una ruptura requiere `Contract v2`.
6. Ningún Engine conoce el nombre del módulo que lo consume.
7. Un nuevo módulo se construye primero reutilizando contratos existentes. Solo si el dominio no puede expresarse mediante ellos se crea un nuevo contrato o, en última instancia, un nuevo Business Engine.

> Esta jerarquía — Engine → Capabilities → Contract → Blueprint → Module — es lo que distingue a Quantum de un ERP con módulos o plugins. No es una diferencia de nomenclatura: es la decisión arquitectónica que permite que el sistema crezca durante años sin multiplicar su complejidad. Cada capa tiene una sola responsabilidad; cada separación elimina una fuente de ambigüedad.

**Evolución futura:** cuando el número de módulos por Engine crezca o coexistan múltiples versiones de contrato en producción, las Capabilities y sus Contracts pasarán de ser declarativos a ser **artefactos verificables en tiempo de carga**. Ver [ADR-014](#adr-014-capability-discovery--contratos-verificables-en-tiempo-de-carga).

---

#### P-ENG-004 — Business Blueprints

Responde: **¿cómo se combinan múltiples contratos para construir soluciones de negocio?**

Un módulo que opera sobre un único Engine es el caso simple. El caso general es un módulo que necesita capacidades de **múltiples Engines simultáneamente**: activos físicos del Inventory Engine, personal en campo del Service Engine y planificación del Project Engine. El modelo Engine → Contract → Module no cubre ese escenario sin introducir lógica de composición dentro de alguno de los Engines — lo que violaría P-ENG-001.

El **Business Blueprint** resuelve este caso. Es una capa de composición declarativa que ensambla uno o varios Business Contracts sin implementar ningún comportamiento propio.

```
Business Engine A          Business Engine B          Business Engine C
      ↓                          ↓                          ↓
  Contract A v1              Contract B v1              Contract C v1
      ↓___________________________|___________________________|
                                  ↓
                         Business Blueprint
                    (composición declarativa — sin lógica)
                                  ↓
                        Module Configuration
                                  ↓
                        Business Module (Runtime)
```

**El Blueprint:**
- Nunca implementa comportamiento operativo.
- Nunca modifica un Engine ni un Contract.
- No contiene lógica específica de ningún Engine.
- Solo declara qué Contracts consume y en qué versión.
- Puede reutilizarse entre múltiples módulos.
- Puede evolucionar independientemente de los módulos que lo consumen.

**Analogía:**

Si el Business Engine es el motor y el Business Contract es el estándar del pistón, el Business Blueprint es el **plano completo del vehículo**: decide qué motor montar, qué transmisión usar, qué sistema eléctrico incorporar. El automóvil no modifica ninguna de esas piezas — simplemente las integra siguiendo el plano.

**Ejemplos:**

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
used_by:
  - KEEPME
  - CELEBRATE
```

```yaml
blueprint: CAMPAIGN_BLUEPRINT
version: 1
description: >
  Módulos que combinan pipeline comercial, producción de contenido
  y planificación de proyecto en un solo flujo de trabajo.
contracts:
  - engine: crm-service
    contract: v1
  - engine: creative-service
    contract: v1
  - engine: project-service
    contract: v1
used_by:
  - MARKETING_OPS
```

**Tabla de capas actualizada:**

| Capa | Responsabilidad | Quién la define |
|------|-----------------|-----------------|
| **Business Engine** | Implementa la lógica operacional reutilizable | Equipo de plataforma |
| **Capabilities** | Catálogo de lo que el Engine sabe hacer | Equipo de plataforma |
| **Business Contract** | Interfaz estable y versionada que expone Capabilities | Equipo de plataforma |
| **Business Blueprint** | Composición declarativa de uno o varios Contracts | Equipo de plataforma / arquitectura |
| **Business Module** | Selecciona un Blueprint y lo parametriza para su dominio | Equipo de producto |

**Corolarios:**

1. Un módulo puede consumir uno o varios Business Contracts — siempre a través de un Blueprint, nunca directamente.
2. Un Engine nunca conoce qué Blueprints lo referencian ni qué módulos lo consumen.
3. La reutilización ocurre tanto a nivel de Contract (varios Blueprints usan el mismo Contract) como de Blueprint (varios módulos usan el mismo Blueprint).
4. La incorporación de un nuevo módulo debe resolverse primero reutilizando Blueprints existentes antes de crear uno nuevo.
5. Solo cuando una necesidad no pueda expresarse mediante la composición de Contracts existentes se evaluará la creación de un nuevo Contract o, en última instancia, de un nuevo Business Engine.

---

#### P-ENG-005 — Business Runtime

Responde: **¿quién convierte la configuración declarativa en comportamiento ejecutable?**

El modelo Engine → Capabilities → Contract → Blueprint → Configuration es declarativo en su totalidad. Nadie ha respondido todavía quién **ejecuta** esa declaración: quién lee que KeepMe activa `ASSET_REGISTRY`, `TRANSFER` y `QR_BARCODE`, y construye el pipeline que efectivamente procesa esas operaciones. Ese es el **Business Runtime**.

El Business Runtime es la pieza de la plataforma que une el mundo del módulo con el mundo del Engine. Ningún módulo habla directamente con un Engine — siempre habla con el Runtime.

```
Business Module
      │
      │ "soy KeepMe, uso el INVENTORY_ONLY Blueprint"
      ↓
Module Configuration
      │
      │ "KeepMe activa: ASSET_REGISTRY, TRANSFER, QR_BARCODE, KITS, AUDIT_TRAIL"
      ↓
Business Runtime              ← punto de control de la plataforma
      │
      ├── 1. Resuelve el Blueprint referenciado
      ├── 2. Valida que las Capabilities declaradas existen en el Contract
      ├── 3. Verifica el grafo de requires (TRANSFER → ASSET_REGISTRY ✓)
      ├── 4. Construye el pipeline con solo las Capabilities activas
      └── 5. Enruta cada operación al Engine via el Contract
      │
      ↓
Business Contract → Business Engine
```

**El Engine recibe peticiones del Runtime, no del módulo.** El módulo conoce su configuración; el Engine ejecuta la operación. El Runtime es el único que conoce la relación entre ambos.

**Responsabilidades del Runtime:**

| Responsabilidad | Descripción |
|-----------------|-------------|
| Resolución de Blueprint | Carga el Blueprint referenciado por la Module Configuration desde el Blueprint Registry |
| Validación de Capabilities | Verifica que las Capabilities declaradas existen en los Contracts del Blueprint |
| Validación de dependencias | Verifica el grafo de `requires` — si `RESERVATION` está activo, `AVAILABILITY_CALENDAR` y `ASSET_REGISTRY` también deben estarlo |
| Pipeline construction | Construye el pipeline de ejecución con solo las Capabilities activas para este módulo |
| Routing | Enruta cada petición al Engine correcto según el Contract |
| Isolation | Garantiza que un módulo no puede invocar Capabilities que no declaró en su configuración |

**El vocabulario del Runtime:**

El Runtime trabaja con metadatos de plataforma. Eso es todo. El listado de lo que el Runtime conoce es completo y cerrado:

| Conoce | No conoce |
|--------|-----------|
| `Blueprint` | activo |
| `Capability` | proyecto |
| `Contract` | cliente |
| `Dependency` | orden |
| `Engine` | factura |
| `BusinessContext` | SKU |
| `RuntimeContext` | campaña |
| `CapabilityDescriptor` | departamento |

Si alguna clase del Runtime importa una entidad de dominio (`Asset`, `Project`, `Deal`, `WorkOrder`), es una violación de este principio. El Runtime no sabe qué es un activo. Solo sabe que `ASSET_REGISTRY` es una Capability con ciertas dependencias y ciertos eventos.

Esta restricción no es cosmética. Es lo que garantiza que el mismo Runtime puede ejecutar indistintamente Inventory, CRM, Creative y Manufacturing sin cambiar una línea de código.

**Lo que el Runtime nunca hace:**

- No implementa lógica de ningún Engine.
- No modifica Capabilities ni Contracts.
- No contiene bifurcaciones (`if`, `switch`) sobre el nombre del módulo.
- No expone diferencias de comportamiento entre módulos — esas diferencias están en la configuración, no en el Runtime.
- No envía el nombre del módulo a ningún Engine — el Engine recibe `BusinessContext`, nunca `ModuleName`.
- No importa clases de dominio de negocio — trabaja exclusivamente con los tipos del vocabulario de plataforma listado arriba.

**Objetos formales del Runtime:**

Estos tres objetos son las piezas de datos que el Runtime produce, consume y propaga. Son las interfaces que Sprint 6 debe diseñar antes de escribir una línea de código.

**`CapabilityDescriptor`** — representa una Capability como objeto, no como documento Markdown. Es lo que vive en el Capability Registry.

```
CapabilityDescriptor {
  id:                 String          // e.g. "ASSET_REGISTRY"
  version:            Int             // versión del descriptor
  dependencies:       List<String>    // Capabilities que deben estar activas (requires)
  permissions:        List<String>    // permisos que activa esta Capability
  events:             EventSchema     // { publishes: [...], consumes: [...] }
  configurationSchema: JsonSchema     // validación de los valores de configuración
}
```

**`BusinessContext`** — el único objeto que un Engine recibe. No contiene el nombre del módulo. El Engine no sabe ni puede saber quién lo invocó.

```
BusinessContext {
  tenantId:       String              // identificador del tenant
  capabilities:   Set<String>         // Capabilities activas para esta invocación
  permissions:    Set<String>         // permisos en efecto
  configuration:  Map<String, Object> // valores de configuración del Blueprint
  correlationId:  String              // trazabilidad
}
```

**`RuntimeContext`** — el objeto más importante de toda la plataforma Quantum. Es el resultado de que el Runtime procese un Blueprint completo. Representa el pipeline compilado y validado, listo para ejecutar.

```
Blueprint
    ↓  resolución
Contracts por Engine
    ↓  activación
CapabilityDescriptors activos
    ↓  validación del grafo de requires
Configuration validada
    ↓  resolución de permisos
Permissions consolidadas
    ↓  registro de eventos
EventSchema consolidado
    ↓  compilación
RuntimeContext           ← objeto final; inmutable hasta recarga
```

`RuntimeContext` es inmutable una vez compilado. Toda petición de un módulo viaja con su `RuntimeContext` ya construido — el Runtime no recomputa en cada llamada.

**Registros del Runtime:**

| Registro | Responsabilidad |
|----------|----------------|
| **Capability Registry** | Almacena los `CapabilityDescriptor` de cada Engine. El Runtime lo consulta para validar que una Capability existe y resolver sus dependencias. |
| **Blueprint Registry** | Almacena los archivos `.yml` de Blueprint versionados. El Runtime los descubre y carga al activar un módulo. Nunca usa `latest` — siempre versión explícita. |

**Conexión con ADR-014:** el Business Runtime es el punto natural donde vivir Capability Discovery. Hoy la validación es manual (en diseño); cuando se implemente ADR-014, el Runtime ejecutará esa validación automáticamente en tiempo de carga, antes de que el pipeline se construya.

**Corolarios:**

1. Todo acceso de un módulo a un Engine pasa por el Runtime — sin excepción.
2. El Runtime no modifica el comportamiento de ninguna Capability — solo decide si está activa o no.
3. Un módulo con la misma configuración produce exactamente el mismo `RuntimeContext` en cualquier instancia del Runtime.
4. El Runtime es stateless respecto al dominio: no guarda estado de negocio, solo estado de configuración compilado.
5. Un Engine que recibe `BusinessContext` sin `ModuleName` es un Engine correctamente aislado — si necesita el nombre del módulo para funcionar, hay una violación de P-ENG-001.

---

#### P-ENG-006 — Módulos como Artefactos Controlados

Responde: **¿quién puede crear un módulo y bajo qué proceso?**

Los módulos de negocio no son extensiones públicas ni plugins instalables por terceros. Cada módulo es un artefacto interno de la plataforma Quantum, desarrollado bajo los estándares arquitectónicos de la organización, versionado junto al resto del ecosistema y registrado explícitamente en el Runtime durante el proceso de despliegue.

**La incorporación de un nuevo módulo es una decisión de ingeniería, no una acción de un usuario final.**

El Runtime no descubre módulos dinámicamente en producción. Únicamente carga módulos previamente registrados, validados y aprobados durante el proceso de construcción y despliegue de la plataforma.

**El ciclo de vida de un módulo:**

```
Idea de negocio
        ↓
Diseño del Blueprint (business-blueprint.yml)
        ↓
Revisión arquitectónica (verifica P-ENG y P-ARC)
        ↓
Validación automática (Blueprint Compiler + Architecture Validation Suite)
        ↓
CI/CD
        ↓
Registro en Module Registry (vía inventory-engine.yml o equivalente)
        ↓
Despliegue
        ↓
El Runtime lo carga al iniciar la plataforma
```

**Corolarios:**

1. Solo un equipo autorizado puede crear o modificar módulos.
2. Todo módulo debe cumplir el Business Blueprint Specification antes de poder registrarse.
3. La instalación de un módulo forma parte del ciclo de despliegue de Quantum, no de la operación diaria del ERP.
4. Los usuarios administran la configuración y el ciclo de vida de los módulos existentes, pero nunca incorporan código nuevo al Runtime.
5. Todo módulo pasa por revisión arquitectónica, validación automática y CI/CD antes de ser ejecutable.

**Analogía:** el Runtime de Quantum soporta múltiples módulos como el kernel de Linux soporta miles de drivers. Pero los drivers oficiales siguen un proceso de integración y gobernanza — no cualquiera modifica el kernel. KeepMe, Celebrate y SWAG son productos de negocio oficiales construidos sobre el Runtime, no plugins que alguien instala en producción.

> Quantum no es una plataforma de plugins. Es una plataforma de dominios de negocio gobernados.

---

#### P-ENG-007 — Business Journeys *(deferred)*

Responde: **¿cómo se modela una cadena operacional que atraviesa múltiples Engines?**

El modelo Engine → Capabilities → Contract → Blueprint → Runtime describe cómo se ensamblan los Engines. Lo que todavía no describe es **cómo se coordina un proceso de negocio que cruza varios de esos Engines en secuencia**, donde cada etapa depende del resultado de la anterior, pueden existir compensaciones si una etapa falla, y el proceso tiene SLA definidos por transición.

Eso no es un Workflow (demasiado pequeño — el Workflow vive dentro de un módulo). Es un **Business Journey**: una cadena operacional completa que conecta dominios distintos, donde ningún Engine hace todo — cada uno hace su parte — y hay un orquestador que mantiene el contexto global.

**Ejemplo — SWAG Delivery Journey:**

```
crm.deal.won
      ↓
  Creative Engine          genera entregables aprobados por el cliente
      ↓ creative.deliverables.approved
  Manufacturing Engine     produce los elementos físicos (mercancía de marca)
      ↓ manufacturing.work_order.completed
  Inventory Engine         registra los activos producidos
      ↓ inventory.asset.created
  Service Engine           programa la instalación o entrega en campo
      ↓ service.report.submitted
  CRM Engine               marca la oportunidad como entregada
```

Ningún Engine conoce los otros cuatro. El **Business Journey** es quien:
- Conoce qué Engine inicia el proceso y con qué evento
- Sabe qué eventos debe esperar de cada Engine para avanzar a la siguiente etapa
- Define las compensaciones (qué ocurre si Manufacturing falla — ¿se cancela el creative? ¿se notifica al CRM?)
- Gestiona los SLA de cada transición
- Mantiene el estado global del proceso sin que ningún Engine lo necesite

**Relación con el patrón Saga:** un Business Journey es una Saga expresada desde el dominio de negocio, no desde la infraestructura. La diferencia no es técnica — es de nivel de abstracción: un desarrollador de producto debería poder declarar un Journey sin conocer cómo se implementa la compensación subyacente.

**Extensión futura del schema Blueprint:**

```yaml
# Hoy:
engines:
  - creative
  - manufacturing
  - inventory
  - service
  - crm

# Futuro:
journeys:
  - swag_delivery_v1     # el Journey ya conoce la secuencia, eventos y compensaciones
```

**Por qué no ahora (YAGNI):**

Un Journey requiere orquestación distribuida con estado persistente, gestión de compensaciones y visibilidad end-to-end. Esa infraestructura tiene un coste operacional real. Hoy, con los primeros Engines apenas definiéndose, implementar Journeys añadiría complejidad sin beneficio proporcional. El trigger correcto es cuando existan al menos dos Engines activos en producción y aparezca el primer proceso de negocio que los cruce de forma recurrente.

**Lo que SWAG valida sin necesitar Journeys:**

SWAG como Blueprint de prueba no necesita Journeys para validar el modelo P-ENG. Lo que prueba es que el Runtime puede activar Capabilities de tres Engines distintos sin que ninguno conozca a los otros. El Journey añadiría la capa de orquestación de la secuencia — que es un problema diferente y posterior.

> Business Journeys son el horizonte natural del modelo P-ENG. Cuando existan, Quantum habrá evolucionado de una plataforma de ensamblaje de Engines a una plataforma de orquestación de procesos de negocio completos. Ese es el objetivo de largo plazo.

---

### P-ARC — Platform Architecture Constraints

Dos principios que gobiernan cómo se construye la plataforma, no qué hace. Se aplican a toda decisión de diseño interno: Runtime, Registries, Capability Graph, Validators.

#### P-ARC-001 — Anti-Complejidad

> **Toda nueva abstracción debe eliminar complejidad, nunca desplazarla.**

El modelo P-ENG ya define abstracciones suficientes: Engine, Capability, Contract, Blueprint, Runtime. Añadir más capas está justificado únicamente cuando una abstracción nueva reduce la complejidad total del sistema — no cuando la oculta en otro lugar.

**Señales de alerta:**

- Una clase existe porque "suena bien" en la jerarquía, pero no tiene una responsabilidad que ninguna otra clase tenga.
- Para entender el comportamiento de X hay que leer tres capas de indirección antes de llegar al código que hace algo.
- El test de X requiere mockear cuatro colaboradores que no tienen lógica real.
- La documentación de una abstracción describe qué hace, no por qué existe.

**La pregunta de validación:** antes de introducir cualquier nueva clase, interfaz o capa en el Runtime o en los Registries, responder: ¿qué complejidad elimina? Si la respuesta es "organiza mejor el código" o "sigue el patrón X", no cumple el criterio.

El riesgo específico de este proyecto es que el Runtime se convierta en un framework interno tan complejo que solo quien lo diseñó pueda modificarlo. Ese resultado sería exactamente lo contrario de la filosofía de Quantum.

#### P-ARC-002 — Dominio-Ignorante

> **El Runtime y los Registries nunca importan clases de dominio de negocio.**

El vocabulario de la plataforma (Blueprint, Capability, Contract, Dependency, Engine, BusinessContext, RuntimeContext, CapabilityDescriptor) es el único vocabulario que el Runtime conoce. Los conceptos de negocio (activo, proyecto, cliente, orden, campaña, SKU) son invisibles para la plataforma.

Esta separación es verificable automáticamente: ninguna clase de `quantum-platform` debería importar una clase de `inventory-service`, `crm-service` ni de cualquier Engine. Si esa importación aparece, es una violación de P-ARC-002.

**Consecuencia directa:** el Runtime puede ejecutar un Engine sobre el que nada sabe — solo necesita su `CapabilityDescriptor` y el `BusinessContext` para activarlo. Eso es lo que hace al modelo P-ENG composable.

---

### P-CLS — Taxonomía de Servicios de Quantum

> **Esta no es una guía de diseño. Es el mapa conceptual permanente de Quantum.**
> Cada componente nuevo que se incorpore a la plataforma debe clasificarse antes de diseñarse.
> La categoría determina qué principios aplican, qué métricas son relevantes y cómo evoluciona el componente.

Un servicio solo puede aspirar a ser excelente dentro de la categoría correcta. Aplicar los principios P-ENG a un servicio de plataforma produce fricciones artificiales. Aplicar criterios de infraestructura a un Engine de negocio produce abstracciones mal enfocadas. La clasificación es la primera decisión de diseño.

Quantum tiene cuatro capas de componentes. Cada capa tiene principios, métricas de calidad y responsabilidades propias.

```
                        Quantum Platform
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
 Platform Services      Foundation Services    Business Engines
        │                      │                      │
 identity-service        project-service       inventory-service
 gateway-service         calendar-service      crm-service
 runtime-service         document-service      creative-service
 notification-service    organization-service  manufacturing-service
 audit-service           workflow-service      service-service
 configuration-service

        └──────────────────────┴──────────────────────┘
                               │
                       Business Modules
                               │
                  KeepMe · Celebrate · SWAG · CustomX ...
```

#### Tabla de clasificación

| Categoría | Pregunta que responde | Principios | Ejemplo |
|---|---|---|---|
| **Platform Services** | ¿Cómo existe la plataforma? | P-PLT | identity-service |
| **Foundation Services** | ¿Qué necesitan todos los negocios? | P-FND | project-service |
| **Business Engines** | ¿Qué sabe hacer la plataforma operacionalmente? | P-ENG | inventory-service |
| **Business Modules** | ¿Cómo se ensambla un negocio concreto? | Blueprint YAML | KeepMe |

#### Regla de clasificación

> Un servicio pertenece a la categoría más baja que cubra completamente su responsabilidad.
>
> - Si su falla detiene la plataforma entera → **Platform Service**
> - Si todo Engine potencialmente necesita acceder a su dominio → **Foundation Service**
> - Si implementa comportamiento operacional reutilizable de un dominio de negocio → **Business Engine**
> - Si solo existe para un negocio concreto → **Business Module** (declarativo, sin código nuevo)

#### Reglas de dependencia entre capas (P-CLS)

Estas reglas son estructurales e inviolables. Una violación requiere un ADR que la justifique.

| Regla | Descripción |
|---|---|
| **P-CLS-DEP-01** | Un Platform Service nunca depende de un Business Engine ni de un Foundation Service. La plataforma no conoce el negocio. |
| **P-CLS-DEP-02** | Un Foundation Service puede consumir Platform Services. Nunca depende de un Business Engine. |
| **P-CLS-DEP-03** | Un Business Engine puede consumir Platform Services y Foundation Services. Nunca importa ni llama directamente a otro Business Engine. La coordinación entre Engines ocurre vía eventos de dominio o vía el Platform Runtime, nunca mediante llamada directa. |
| **P-CLS-DEP-04** | Un Business Module no contiene lógica de negocio. Es únicamente un Blueprint declarativo (YAML). No importa clases Java de ningún Engine. |
| **P-CLS-DEP-05** | La dirección permitida de dependencias es siempre descendente: Module → Engine → Foundation → Platform. Ninguna capa depende de la capa que está encima. |

```
Business Module     — solo Blueprint YAML, sin lógica
      ↓ (declara)
Business Engine     — implementa operaciones; consume Foundation + Platform
      ↓ (consume)
Foundation Service  — modela dominios transversales; consume Platform
      ↓ (consume)
Platform Service    — hace que la plataforma exista; sin dependencias de negocio
```

**Verificación ArchUnit (Sprint 8):**
```
noClasses().that().resideInPackage("..platform..")
           .should().dependOnClassesThat()
           .resideInPackage("..inventory..").orShould()
           .resideInPackage("..crm..").orShould()
           .resideInPackage("..project..");
```

---

### P-PLT — Platform Service Architecture

Los Platform Services hacen que la plataforma exista. Sin ellos, ningún Engine puede operar, ningún Blueprint puede compilarse, ningún módulo puede autenticarse. Su falla no afecta a un módulo — afecta a toda la plataforma.

**Servicios de plataforma actuales:**

| Servicio | Responsabilidad |
|---|---|
| `identity-service` | Autenticación, autorización, identidades de usuario y servicio, JWT |
| `gateway-service` | Punto único de entrada, routing, rate limiting, autenticación en edge |
| `runtime-service` | Blueprint Compiler, Registries, Module Loader, Engine Dispatcher |
| `notification-service` | Entrega de notificaciones (email, push, in-app) independiente del dominio |
| `audit-service` | Registro inmutable de acciones y eventos del sistema |
| `configuration-service` | Configuración dinámica de la plataforma sin redeploy |

**Nunca aplica a Platform Services:**
- P-ENG (no tienen Capabilities, Contracts ni Blueprints)
- P-FND (no son consumidos por Engines como parte de su dominio)

---

#### P-PLT-001 — Zero Trust Interno

> **Ningún Platform Service confía en ninguna llamada interna sin verificación explícita.**

La red interna no es un perímetro de seguridad. Toda llamada entre servicios — sin importar el origen — presenta credencial verificable. No existe el concepto de "llamada de confianza" por provenir de una IP interna o de otro microservicio de la misma plataforma.

Implementación en Quantum: Service JWTs de corta duración (TTL 1h) firmados con RSA, verificados en cada llamada. Ver P-SEC-002.

**Corolario:** si se compromete un servicio interno, el blast radius está limitado a las credenciales de ese servicio — nunca a toda la plataforma.

---

#### P-PLT-002 — Stateless por Diseño

> **Los Platform Services no guardan estado de sesión en memoria.**

Todo estado de sesión vive en Redis (caché distribuida) o en base de datos. Un Pod que se reinicia, migra o escala horizontalmente no pierde ninguna sesión activa. El cliente ni se entera.

**Verificación:** un Platform Service puede ser reiniciado en cualquier momento sin degradación de servicio observable por el usuario final.

---

#### P-PLT-003 — Identidad de Servicio

> **Cada servicio de la plataforma tiene una identidad única registrada en identity-service.**

No existen claves compartidas entre servicios. No existe una clave maestra interna. Cada servicio se autentica con sus propias credenciales, su propio par de claves. La revocación de un servicio compromiso no afecta a ningún otro.

---

#### P-PLT-004 — Plataforma Opaca al Dominio

> **Los Platform Services nunca importan, entienden ni procesan lógica de negocio de ningún Engine.**

El `gateway-service` no sabe qué es un activo. El `identity-service` no sabe qué es una reserva. El `notification-service` no entiende el flujo de un proyecto. Reciben eventos y mensajes tipificados, no conocimiento de dominio.

**Verificación ArchUnit:** ninguna clase de `gateway-service`, `identity-service`, `runtime-service` ni `notification-service` importa una clase de `inventory-service`, `crm-service` ni de cualquier Business Engine.

---

#### P-PLT-005 — Alta Disponibilidad No Negociable

> **Los Platform Services operan con redundancia activa. Una instancia caída no interrumpe el servicio.**

Mínimo dos réplicas en producción. Health checks configurados. Circuit breakers activos. El SLA de los Platform Services es el SLA de la plataforma completa.

**Orden de recuperación ante fallo total:**

```
1. identity-service
2. gateway-service
3. runtime-service
4. notification-service / audit-service (orden indiferente)
5. Business Engines
6. Business Modules (se activan automáticamente al recuperarse el Runtime)
```

---

### P-FND — Foundation Service Architecture

Los Foundation Services modelan dominios transversales que no son infraestructura de plataforma, pero tampoco pertenecen a ningún Engine de negocio específico. Todo Engine podría necesitarlos. Ningún Engine los posee.

La diferencia entre un Foundation Service y un Business Engine:

| | Foundation Service | Business Engine |
|---|---|---|
| **¿Quién lo consume?** | Cualquier Engine, cualquier módulo | Los módulos que declaran ese Engine en su Blueprint |
| **¿Tiene Capabilities?** | No — tiene una API estable | Sí — catálogo de Capabilities con Contract |
| **¿Tiene Blueprint?** | No | Sí |
| **Ejemplo** | `project-service` — cualquier Engine puede referenciar un proyecto | `inventory-service` — solo módulos que necesitan gestión de activos |

**Foundation Services actuales y proyectados:**

| Servicio | Dominio transversal |
|---|---|
| `project-service` | Proyectos, fases, miembros, estados, departamentos |
| `calendar-service` | Eventos de calendario, disponibilidad, bloqueos |
| `document-service` | Archivos, versiones, permisos de documento |
| `organization-service` | Organizaciones, equipos, jerarquía interna |
| `workflow-service` | Aprobaciones, flujos de estados entre servicios |

**`project-service` — el caso más importante:**

Hoy `project-service` gestiona proyectos, fases, miembros y departamentos. Mañana podría extenderse con Milestones, Timelines, Dependencias, Risks y Deliverables. Todo Engine — Inventory, CRM, Creative, Manufacturing — puede necesitar referenciar un Proyecto. Eso lo convierte en Foundation Service, no en Engine.

> La pregunta que determina la categoría: ¿algún futuro Engine podría no necesitar este dominio? Si la respuesta es "difícilmente" → Foundation Service.

---

#### P-FND-001 — Dominio Transversal

> **Un Foundation Service modela un dominio que cualquier Engine podría consumir. Si solo un Engine lo necesita, el dominio pertenece a ese Engine.**

**Señal de alarma:** si un Foundation Service tiene lógica específica para un Engine (ej: `if (engine == "inventory") { ... }`), ese código está en el lugar equivocado. Esa lógica pertenece al Engine.

---

#### P-FND-002 — API como Contrato Estable

> **Los Foundation Services exponen APIs versionadas estables. No tienen Business Contracts ni Capabilities — su interfaz es su API REST.**

A diferencia de los Business Engines, los Foundation Services no participan en el sistema de Blueprints. Un Engine los consume directamente via API (síncrona) o eventos (asíncrona). La evolución de su API sigue los mismos principios de versionado que cualquier contrato de la plataforma.

---

#### P-FND-003 — Sin Lógica de Engine

> **Un Foundation Service nunca implementa comportamiento operacional que pertenezca a un Engine.**

`project-service` no sabe cómo reservar un activo físico — eso es Inventory Engine. `calendar-service` no sabe cómo asignar personal a un evento — eso es Service Engine. Si un Foundation Service empieza a acumular lógica de Engine, es una señal de que ese dominio está siendo absorbido incorrectamente.

---

#### P-FND-004 — Consumible por Cualquier Engine

> **Los Foundation Services están diseñados para ser consumidos sin acoplamiento con ningún Engine específico.**

La API de `project-service` es agnóstica al Engine que la llama. No existe un endpoint `GET /projects/for-inventory` ni lógica que bifurque según el consumidor. El Foundation Service provee la información; el Engine decide cómo usarla.

---

# PARTE II — EL DOMINIO

---

## 4. Modelo de Dominio

El modelo de dominio describe las entidades del negocio, sus atributos esenciales y sus relaciones. No son tablas de base de datos. Son los objetos conceptuales que representan la realidad operacional de Brandex.

### Entidades principales

---

**COMPANY** — Empresa cliente o proveedora

Una empresa del mundo real que tiene relación comercial con Brandex. Puede ser cliente (genera proyectos), proveedor (ofrece recursos para proyectos), o ambos. Es una entidad de referencia compartida entre el CRM y el Marketplace, con perspectivas distintas en cada dominio.

Atributos esenciales: identidad única, nombre legal, tipo (cliente / proveedor / ambos), información de contacto, documentación legal, historial de relación.

---

**CONTACT** — Persona dentro de una empresa

Individuo específico que representa a una empresa en una interacción. Un cliente tiene varios contactos: el decisor, el usuario final, el área de compras. Un proveedor tiene contactos operativos y comerciales.

---

**LEAD** — Oportunidad comercial

Una oportunidad de negocio en exploración. Existe solo en el dominio comercial. Tiene una probabilidad estimada de cierre, un valor potencial, y atraviesa etapas de calificación hasta convertirse en Deal o ser descartado.

---

**DEAL** — Oportunidad comprometida

Un Lead que ha avanzado a propuesta formal y negociación activa. Tiene un valor acordado, fechas de evento, un brief preliminar y departamentos de Brandex involucrados. Un Deal ganado es el origen de todo Proyecto.

---

**PROJECT** — La entidad central. El Aggregate Root del sistema.

Un Proyecto representa la ejecución completa de un compromiso con un cliente: desde la aprobación hasta el cierre. Es la entidad que coordina el trabajo de todos los departamentos. Toda orden, toda reserva de activos, todo entregable creativo, todo costo — existe en referencia a un Proyecto.

Atributos esenciales: código interno, nombre, cliente, timeline (fechas clave), estado actual dentro de la máquina de estados, fase actual, departamentos involucrados, equipo asignado, presupuesto, documentos asociados.

Un Proyecto no es solo un registro de base de datos. Es el punto de coordinación de la operación completa.

---

**BRIEF** — Especificación del cliente

El documento que describe qué quiere el cliente. Puede ser un documento externo adjunto o un formulario estructurado dentro del sistema. El Brief es el input para el trabajo creativo y la planificación de producción.

---

**PROJECT MEMBER** — Participante de un proyecto

Un usuario interno que tiene un rol específico en un proyecto: Project Manager, Líder de departamento, o Miembro del equipo. Los miembros de un proyecto tienen acceso a la Ficha Maestra de ese proyecto.

---

**WORK ORDER** — Orden de trabajo

La instrucción formal a un departamento para que ejecute su parte dentro de un proyecto. Hay una Work Order por departamento por proyecto. Una Work Order contiene líneas de trabajo que especifican qué se necesita, en qué cantidad y en qué fecha.

Relaciones: pertenece a un Proyecto, tiene un Departamento responsable, contiene OrderLines.

---

**ORDER LINE** — Línea de una orden

Un requerimiento específico dentro de una Work Order. Puede referenciar: un Activo físico propio de Brandex, una Entidad Dinámica (vehículo, equipo de sonido), o un Recurso Externo contratado vía Marketplace. Tiene estado propio: pendiente, reservado, confirmado, despachado, retornado.

---

**ASSET** — Activo físico

Un elemento físico propiedad de Brandex: estructura de escenario, pantalla LED, mueble, vehículo de transporte. Tiene identificación única, estado (disponible, en uso, en mantenimiento, dado de baja) y un historial de asignaciones y mantenimiento.

Diferencia con Entidad Dinámica: los Activos son elementos catalogados con propiedades fijas y trazabilidad de unidades físicas individuales. Las Entidades Dinámicas son categorías con atributos configurables.

---

**DYNAMIC ENTITY** — Entidad con esquema configurable

Un objeto del negocio cuyos atributos no son fijos en el código, sino configurados en el sistema. Vehículos, Speakers, Venues, Consumibles. Un Vehículo tiene placa, capacidad y tipo de combustible. Un Speaker tiene potencia, respuesta de frecuencia y tipo de conectores. Estos atributos varían por categoría y son configurados por el administrador, no por el desarrollador.

---

**EXTERNAL RESOURCE** — Recurso contratado externamente

Un servicio o bien contratado a un proveedor para un proyecto específico. Un DJ, un equipo de catering, un venue alquilado, transporte especializado. Tiene un contrato asociado, un monto acordado y un estado de entrega.

---

**CONTRACT** — Contrato con proveedor

El acuerdo formal entre Brandex y un proveedor externo para proveer un recurso específico para un proyecto. Tiene monto, términos de pago, fechas y estado.

---

**DISPATCH** — Operación de despacho o retorno

Un despacho agrupa un conjunto de activos y recursos que se transportan hacia o desde un punto de evento. Tiene ruta, vehículo, conductor, horario y estado.

---

**TIMELINE** — Cronograma del proyecto

Las fechas clave de un proyecto: fecha de inicio de producción, fecha de instalación, fecha del evento, fecha de retorno. El Timeline es un componente del Proyecto, no una entidad independiente.

---

**COST** — Costo del proyecto

Cada costo asociado a un proyecto: costo de activos reservados, costo de recursos externos contratados, costo de fabricación, costo de transporte. Tiene una categoría, un monto presupuestado y un monto real. La diferencia entre presupuestado y real es la métrica de control financiero del proyecto.

---

**DOCUMENT** — Archivo adjunto

Un archivo (imagen, PDF, modelo 3D, plano, contrato) asociado a cualquier entidad del sistema. Los documentos no se duplican: existe una referencia al archivo en el Media Service y una metadata que describe a qué entidad pertenece y qué tipo de documento es.

---

**DEPARTMENT** — Unidad organizacional

Un departamento de Brandex que participa en la ejecución de proyectos. Los departamentos son configuración, no código. Pueden cambiar su nombre, su código, sus módulos activos, sin modificar el software.

---

**PROJECT STATE** — Estado en la máquina de estados

Un momento específico en el ciclo de vida de un proyecto. Los estados son configuración almacenada en base de datos, no un enum en el código. Cada estado pertenece a una fase, tiene un color derivado de esa fase, y define qué transiciones son permitidas desde él.

---

**NOTIFICATION** — Comunicación disparada por eventos

Un mensaje enviado a un usuario (email, notificación interna) en respuesta a un evento del sistema. El contenido se genera desde templates. Las notificaciones no tienen iniciativa propia: son la consecuencia de eventos publicados por otros dominios.

---

### Mapa de relaciones entre entidades

```
COMPANY ────────────────── CONTACT
   │                           │
   │ (cliente)                 │
   ▼                           ▼
 LEAD ──────────────────── DEAL
                               │
                           (ganado)
                               │
                               ▼
                          PROJECT ◄──────────── PROJECT STATE
                          (Aggregate Root)      PROJECT MEMBER
                               │
              ┌────────────────┼────────────────────┐
              │                │                    │
              ▼                ▼                    ▼
         TIMELINE           BRIEF                 COST
              │
              │
     ┌────────┴─────────────────────┐
     │                             │
     ▼                             ▼
 WORK ORDER                   DOCUMENT
     │
     ▼
 ORDER LINE
     │
     ├──────────► ASSET ──────────► DISPATCH
     │
     ├──────────► DYNAMIC ENTITY
     │
     └──────────► EXTERNAL RESOURCE ──► CONTRACT ──► VENDOR (COMPANY)
```

---

## 5. Bounded Contexts y Context Map

### Bounded Contexts

Un Bounded Context define el límite donde un modelo tiene significado consistente. Fuera de ese límite, los mismos términos pueden tener significados distintos. Un "Company" en el CRM es un cliente potencial. Un "Company" en el Marketplace es un proveedor. La misma entidad del mundo real, dos modelos distintos en dos contextos distintos.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              QUANTUM ERP PLATFORM                                │
│                                                                                  │
│  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────────────────┐    │
│  │   IDENTITY      │  │   COMMERCIAL     │  │        OPERATIONS            │    │
│  │                 │  │                  │  │                              │    │
│  │  identity-service   │  │  crm-service     │  │  ┌──────────────────────┐   │    │
│  │                 │  │                  │  │  │  project-service     │   │    │
│  │  User           │  │  Lead            │  │  │  (Aggregate Root)    │   │    │
│  │  Role           │  │  Deal            │  │  │                      │   │    │
│  │  Permission     │  │  Client          │  │  │  Project             │   │    │
│  │  Session        │  │  Contact         │  │  │  Timeline            │   │    │
│  │                 │  │  Activity        │  │  │  ProjectState        │   │    │
│  └─────────────────┘  │  Ticket          │  │  │  ProjectMember       │   │    │
│                        │  Task            │  │  │  Department          │   │    │
│                        └──────────────────┘  │  │  CostCenter          │   │    │
│                                              │  └──────────────────────┘   │    │
│                                              │                              │    │
│                                              │  ┌──────────────────────┐   │    │
│                                              │  │  operations-service       │   │    │
│                                              │  │  WorkOrder           │   │    │
│                                              │  │  OrderLine           │   │    │
│                                              │  │  Dispatch            │   │    │
│                                              │  └──────────────────────┘   │    │
│                                              │                              │    │
│                                              │  ┌──────────────────────┐   │    │
│                                              │  │  inventory-service   │   │    │
│                                              │  │  Asset               │   │    │
│                                              │  │  Stock               │   │    │
│                                              │  │  Maintenance         │   │    │
│                                              │  └──────────────────────┘   │    │
│                                              │                              │    │
│                                              │  ┌──────────────────────┐   │    │
│                                              │  │  entity-registry     │   │    │
│                                              │  │  DynamicEntity       │   │    │
│                                              │  │  EntityType          │   │    │
│                                              │  └──────────────────────┘   │    │
│                                              │                              │    │
│                                              │  ┌──────────────────────┐   │    │
│                                              │  │  creative-service    │   │    │
│                                              │  │  CreativeAsset       │   │    │
│                                              │  │  DesignVersion       │   │    │
│                                              │  │  ApprovalRequest     │   │    │
│                                              │  │  Blueprint / Render  │   │    │
│                                              │  └──────────────────────┘   │    │
│                                              │                              │    │
│                                              │  ┌──────────────────────┐   │    │
│                                              │  │  marketplace-service │   │    │
│                                              │  │  Vendor              │   │    │
│                                              │  │  Contract            │   │    │
│                                              │  │  ExternalResource    │   │    │
│                                              │  └──────────────────────┘   │    │
│                                              └──────────────────────────────┘    │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                          PLATFORM SERVICES                              │    │
│  │   analytics-service  │  notification-service  │  media-service         │    │
│  │   currency-service   │  logistics-service                               │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### Context Map — Relaciones entre contextos

El Context Map describe el tipo de relación entre cada par de bounded contexts. El tipo de relación determina cómo fluye la autoridad sobre el modelo.

---

**Commercial → Operations: Anti-Corruption Layer**

Esta es la relación más importante del sistema. Un "Deal ganado" en el CRM se convierte en un "Proyecto" en Operations. Estas son entidades fundamentalmente distintas con modelos distintos. El CRM no debe contaminar el modelo del Proyecto con conceptos comerciales (probabilidad de cierre, pipeline stage, valor del deal). El dominio Operations no debe contaminar el CRM con conceptos operativos (estados de producción, órdenes de trabajo, activos reservados).

La barrera entre ellos es el evento `DealWon`. El CRM publica el evento. Operations lo consume y crea un Project con su propio modelo, sin heredar la estructura del Deal.

---

**project-service → operations-service: Customer-Supplier**

El project-service define la necesidad (el proyecto existe, tiene departamentos asignados, tiene fechas). El operations-service provee el trabajo (las órdenes de trabajo que ejecutan esa necesidad). operations-service conforma su comportamiento a lo que project-service necesita: no puede crear una orden sin un proyecto válido, no puede despachar si el proyecto no está en la fase correcta.

---

**project-service → inventory-service: Customer-Supplier**

project-service necesita saber si un activo está disponible para las fechas del proyecto. inventory-service provee esa información. Las reservas de activos ocurren en inventory-service pero siempre en referencia a un proyecto de project-service.

---

**operations-service → marketplace-service: Customer-Supplier**

Cuando una línea de orden requiere un recurso externo, operations-service necesita que marketplace-service contrate ese recurso. marketplace-service opera bajo los términos que operations-service establece (proyecto, departamento, fecha de entrega requerida).

---

**Todos los servicios → notification-service: Conformist**

notification-service no define su propio modelo de negocio. Conforma completamente su comportamiento a los eventos que los demás servicios publican. No tiene iniciativa propia. Su única función es traducir eventos en comunicaciones.

---

**Todos los servicios → analytics-service: Conformist**

analytics-service construye read models basados en los eventos que los demás servicios publican. No hace preguntas al sistema: escucha todo lo que pasa y mantiene sus propias proyecciones optimizadas para consulta.

---

### ⚠️ Crítica arquitectónica: el dominio Financiero está indefinido

**Situación actual:** Los centros de costo están en project-service. Los costos reales (lo que finalmente se gastó) no tienen hogar claro. La facturación al cliente no existe como dominio.

**El problema:** Sin un dominio financiero definido, los costos terminan dispersos entre project-service, operations-service y marketplace-service. Nadie tiene la visión completa de cuánto costó realmente un proyecto.

**Recomendación:** Definir el dominio financiero ahora, aunque su implementación sea simple inicialmente. Las entidades financieras (Budget, ActualCost, Invoice, Payment) deben tener un propietario claro. Ver ADR-008.

---

### ⚠️ Crítica arquitectónica: la Company tiene dos representaciones

La misma empresa del mundo real puede ser cliente (CRM) y proveedor (Marketplace). Hoy no hay mecanismo para vincular ambas representaciones.

**Recomendación:** Cada contexto mantiene su propio modelo (Client en CRM, Vendor en Marketplace) con un campo opcional `externalId` que permite vincularlos cuando son la misma empresa real. No se crea un servicio de "Directorio" centralizado, que sería un acoplamiento artificial a esta escala. El vínculo es opcional y cosmético, no operacional.

---

## 6. El Proyecto como Aggregate Root

### Por qué el Proyecto es el centro del sistema

En Domain-Driven Design, un Aggregate Root es la entidad que:
- Controla el acceso a todas las demás entidades dentro de su agregado
- Garantiza las invariantes del dominio
- Es el punto de entrada para todas las operaciones sobre ese agregado
- Publica los eventos que el resto del sistema consume

El Proyecto es el Aggregate Root de Quantum ERP por una razón de negocio, no técnica: **cada departamento de Brandex existe para servir a un proyecto**. No existe una orden de trabajo que no sea de un proyecto. No existe una reserva de activo que no sea para un proyecto. No existe un costo que no pertenezca a un proyecto.

### La Ficha Maestra del Proyecto

La Ficha Maestra del Proyecto es la vista unificada que el sistema expone a coordinadores, líderes y directivos. No es una pantalla de un módulo: es la representación consolidada del estado de todo el sistema referenciada a un proyecto.

La Ficha Maestra contiene:
- **Identidad del proyecto:** código, nombre, cliente, coordinador responsable
- **Estado actual:** en qué fase y estado se encuentra, cuándo fue el último cambio
- **Timeline:** fechas clave del proyecto
- **Departamentos involucrados:** cuál es el estado de cada departamento (pendiente, notificado, en proceso, completado)
- **Órdenes de trabajo activas:** cuántas líneas están pendientes, en proceso, completadas
- **Activos reservados:** qué activos están comprometidos para este proyecto
- **Recursos externos contratados:** proveedores, montos, fechas de entrega
- **Control de costos:** presupuesto vs real, por categoría
- **Documentos:** brief, creativos aprobados, contratos
- **Historial de estados:** línea de tiempo de cada transición con responsable

Esta vista se construye coordinando información de múltiples servicios. El frontend la agrega, no el backend.

### El ciclo de vida del Proyecto controla todo

Cuando el estado de un Proyecto cambia, ese evento es el impulso que activa el trabajo de los demás dominios:

```
ProjectCreated
  → notifications: notificar a coordinador asignado
  → operations-service: crear órdenes iniciales por dept (si aplica)

ProjectStateChanged → APPROVED
  → notifications: notificar a líderes de cada dept involucrado
  → operations-service: habilitar creación de órdenes de producción

ProjectStateChanged → DISPATCHED
  → inventory: confirmar activos como "en uso"
  → logistics: plan de despacho activo

ProjectStateChanged → RETURNED
  → inventory: iniciar proceso de recepción y inspección de activos
  → financial: habilitar reconciliación de costos

ProjectClosed
  → financial: generar estado financiero final
  → inventory: liberar todos los activos del proyecto
  → analytics: actualizar read models de proyecto cerrado
```

### Invariantes del Proyecto

Las siguientes reglas no pueden ser violadas y deben ser garantizadas por project-service:

1. Un Proyecto no puede avanzar a APPROVED si no tiene al menos un departamento asignado
2. Un Proyecto no puede avanzar a DISPATCHED si no tiene órdenes de trabajo confirmadas en todos los departamentos activos
3. Un Proyecto no puede cerrarse si tiene activos marcados como en uso sin fecha de retorno
4. Un Proyecto CANCELLED no puede transicionar a ningún estado operativo
5. Solo puede haber un estado activo por proyecto en cualquier momento

---

## 7. Ownership Matrix

Esta matriz establece sin ambigüedad quién posee cada entidad del negocio, quién puede modificarla, quién puede leerla, y qué eventos publica y consume cada dominio.

### Tabla de ownership

| Entidad | Servicio propietario | Puede escribir | Puede leer | Publica | Consume |
|---|---|---|---|---|---|
| User | identity-service | identity-service | todos (via JWT claims) | UserCreated, UserDeactivated | — |
| Role / Permission | identity-service | identity-service | todos (via JWT) | RoleAssigned | — |
| Lead | crm-service | crm-service | crm, analytics | LeadCreated, LeadQualified, LeadWon, LeadLost | — |
| Deal | crm-service | crm-service | crm, analytics | DealWon, DealLost | — |
| Client (Company) | crm-service | crm-service | crm, project | — | — |
| Contact | crm-service | crm-service | crm | ContactCreated | — |
| CRM Activity | crm-service | crm-service | crm | — | — |
| **Project** | **project-service** | **project-service** | **todos** | **ProjectCreated, ProjectStateChanged, ProjectClosed, ProjectCancelled** | **DealWon** |
| ProjectState (catálogo) | project-service | admin via project-service | todos | — | — |
| Department (config) | project-service | admin via project-service | todos | — | — |
| Timeline | project-service | project-service | todos | TimelineUpdated | — |
| CostCenter | project-service | project-service | project, financial | — | — |
| ProjectMember | project-service | project-service | project | — | — |
| Brief | project-service | project-service | todos | BriefSubmitted, BriefApproved | — |
| CreativeAsset | creative-service | creative-service | project, analytics | CreativeAssetCreated, DesignApproved, DesignRejected | ProjectBriefSubmitted |
| DesignVersion | creative-service | creative-service | creative | DesignVersionSubmitted | — |
| ApprovalRequest | creative-service | creative-service | creative | ApprovalRequested | — |
| WorkOrder | operations-service | operations-service | project, inventory | OrderCreated, OrderConfirmed, OrderDispatched, OrderReturned | ProjectStateChanged |
| OrderLine | operations-service | operations-service | order | OrderLineUpdated | — |
| Dispatch | operations-service | operations-service | logistics, inventory | DispatchStarted, DispatchCompleted | — |
| Asset | inventory-service | inventory-service | order, project | AssetReserved, AssetReleased, AssetDamaged, AssetInMaintenance | OrderConfirmed, ProjectClosed |
| MaintenanceRecord | inventory-service | inventory-service | inventory | MaintenanceCompleted | AssetDamaged |
| EntityType / Fields | entity-registry | admin via entity-registry | todos | — | — |
| DynamicEntity (instance) | entity-registry | entity-registry | order, inventory | EntityCreated, EntityUpdated | — |
| Vendor (Company) | marketplace-service | marketplace-service | marketplace, order | — | — |
| Contract | marketplace-service | marketplace-service | marketplace, financial | ContractCreated, ContractClosed | — |
| ExternalResource | marketplace-service | marketplace-service | order, project | ResourceDelivered | OrderLine external |
| Budget | financial-service | project-service (crea), financial (actualiza) | financial, analytics | BudgetCreated, BudgetAdjusted | ProjectCreated |
| ActualCost | financial-service | financial-service | financial, analytics | CostIncurred | OrderConfirmed, ContractCreated |
| Invoice | financial-service | financial-service | financial | InvoiceGenerated | ProjectClosed |
| Payment | financial-service | financial-service | financial | PaymentReceived | InvoiceGenerated |
| Document / File | media-service | media-service | todos (por URL) | DocumentUploaded | — |
| NotificationLog | notification-service | notification-service | admin | NotificationDelivered, NotificationFailed | muchos eventos |
| Wallet / QPoint | currency-service | currency-service | currency | TransactionCreated | — |
| RouteOptimization | logistics-service | logistics-service | order | — | DispatchStarted |

### Regla de lectura

Que un servicio "pueda leer" una entidad no significa que tenga acceso a la base de datos del propietario. Significa que puede consultar esa entidad a través de la API del servicio propietario o recibir su información a través de eventos.

---

# PARTE III — LOS EVENTOS

---

## 8. Domain Events

Los eventos de dominio son el lenguaje de comunicación del sistema. Cada evento representa algo que ocurrió en el negocio, en tiempo pasado, como hecho irrevocable. Los eventos no son comandos (no dicen qué hacer). Son notificaciones de lo que ya ocurrió.

### Estructura estándar de un evento

Todo evento del sistema tiene la misma estructura base:

```
eventId        : UUID       — identificador único del evento
eventType      : string     — nombre del evento (ej: "ProjectCreated")
aggregateId    : UUID       — ID de la entidad principal del evento
aggregateType  : string     — tipo de la entidad (ej: "Project")
occurredAt     : timestamp  — cuándo ocurrió
causedBy       : UUID       — ID del usuario o servicio que causó el evento
correlationId  : UUID       — para tracing entre servicios
payload        : object     — datos específicos del evento
```

### Catálogo de eventos por dominio

---

#### Dominio: COMMERCIAL (crm-service)

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `LeadCreated` | crm-service | analytics | Actualiza métricas de pipeline |
| `LeadQualified` | crm-service | analytics | Actualiza métricas de pipeline |
| `LeadProposalSent` | crm-service | notifications, analytics | Notificación interna al comercial; actualiza métricas |
| `LeadWon` | crm-service | analytics | Actualiza métricas de cierre |
| `LeadLost` | crm-service | analytics | Actualiza métricas de cierre |
| `DealWon` | crm-service | **project-service**, analytics | **Crea el Proyecto** |
| `DealLost` | crm-service | analytics | Actualiza métricas de deal |

---

#### Dominio: PROJECTS (project-service)

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `ProjectCreated` | project-service | notifications, analytics, **financial** | Notifica al coordinador; crea budget inicial |
| `ProjectDepartmentLinked` | project-service | notifications, operations-service | Notifica al líder del departamento por email |
| `ProjectStateChanged` | project-service | notifications, operations-service, inventory-service, analytics | Actualiza display en todos los módulos; puede habilitar o bloquear operaciones según el nuevo estado |
| `ProjectBriefSubmitted` | project-service | notifications | Notifica al equipo creativo |
| `ProjectBriefApproved` | project-service | notifications, operations-service | Habilita creación de órdenes de producción |
| `ProjectCreativeApproved` | project-service | notifications, operations-service | Habilita órdenes de producción físicas |
| `ProjectStandBy` | project-service | notifications, operations-service, inventory-service | Suspende operaciones activas |
| `ProjectCancelled` | project-service | notifications, operations-service, inventory-service, financial | Libera recursos, cancela contratos pendientes, registra costos incurridos |
| `ProjectClosed` | project-service | notifications, inventory-service, **financial**, analytics | Libera activos; genera estado financiero final; actualiza analytics |
| `TimelineUpdated` | project-service | notifications, operations-service, logistics-service | Puede disparar recalculos de disponibilidad y rutas |

---

#### Dominio: CREATIVE (creative-service)

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `CreativeAssetCreated` | creative-service | analytics | Actualiza métricas de producción creativa |
| `DesignVersionSubmitted` | creative-service | notification-service | Notifica al coordinador que hay una versión lista para revisar |
| `ApprovalRequested` | creative-service | notification-service | Notifica al cliente (o coordinador) que se solicita aprobación |
| `DesignApproved` | creative-service | **project-service**, analytics | **project-service transiciona el proyecto a CREATIVE_APPROVED** |
| `DesignRejected` | creative-service | notification-service | Notifica al equipo creativo con feedback del cliente |
| `DesignRevisionRequested` | creative-service | notification-service | Notifica que se requiere una revisión con cambios específicos |

---

#### Dominio: ORDERS (operations-service)

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `OrderCreated` | operations-service | notifications | Notifica al líder del departamento |
| `OrderConfirmed` | operations-service | inventory-service, **financial**, notifications | Reserva formal de activos; registra costo comprometido |
| `OrderLineExternalRequested` | operations-service | marketplace-service | Inicia proceso de contratación de proveedor |
| `DispatchScheduled` | operations-service | logistics-service, notifications | Optimización de ruta; notificación al equipo de logística |
| `DispatchStarted` | operations-service | inventory-service, analytics | Activos pasan a estado "en tránsito" |
| `DispatchCompleted` | operations-service | inventory-service, project-service, analytics | Activos en destino; puede avanzar estado del proyecto |
| `OrderReturned` | operations-service | inventory-service, analytics | Inicia proceso de recepción en bodega |
| `OrderReturnCompleted` | operations-service | project-service, analytics | Todos los activos devueltos; puede avanzar estado del proyecto |

---

#### Dominio: INVENTORY (inventory-service)

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `AssetCreated` | inventory-service | analytics | Actualiza métricas de inventario |
| `AssetReserved` | inventory-service | operations-service, analytics | Confirma disponibilidad; actualiza stock |
| `AssetUnavailableForReservation` | inventory-service | operations-service, notifications | Orden no puede ser confirmada; notifica al coordinador |
| `AssetReleased` | inventory-service | analytics | Activo vuelve a estar disponible |
| `AssetInspected` | inventory-service | — | Registro de condición post-retorno |
| `AssetDamaged` | inventory-service | notifications, **financial** | Notifica a bodega; registra costo de reparación estimado |
| `AssetSentToMaintenance` | inventory-service | notifications | Activo no disponible hasta mantenimiento |
| `MaintenanceCompleted` | inventory-service | notifications | Activo vuelve a estar disponible |
| `AssetDecommissioned` | inventory-service | analytics | Actualiza inventario activo |

---

#### Dominio: MARKETPLACE (marketplace-service)

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `VendorContracted` | marketplace-service | operations-service, **financial**, notifications | Confirma recurso externo en la orden; registra costo comprometido |
| `ContractAmended` | marketplace-service | **financial**, notifications | Actualiza costo comprometido |
| `ResourceDelivered` | marketplace-service | operations-service, analytics | Línea de orden marcada como cubierta |
| `ContractClosed` | marketplace-service | **financial** | Registra costo real del contrato |

---

#### Dominio: FINANCIAL (financial-service)

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `BudgetCreated` | financial-service | analytics | Actualiza métricas financieras |
| `BudgetAdjusted` | financial-service | notifications, analytics | Notifica si hay desviación significativa |
| `CostIncurred` | financial-service | analytics | Actualiza costos reales del proyecto |
| `InvoiceGenerated` | financial-service | notifications | Notifica al cliente y al director comercial |
| `PaymentReceived` | financial-service | analytics | Actualiza métricas de cobro |

---

#### Dominio: PLATFORM

| Evento | Publisher | Consumidores | Desencadena |
|---|---|---|---|
| `DocumentUploaded` | media-service | notifications (si aplica), analytics | Puede notificar a stakeholders del proyecto |
| `NotificationDelivered` | notification-service | analytics | Registro de entregabilidad |
| `NotificationFailed` | notification-service | analytics | Métrica de fallos de notificación |

---

### Principio de idempotencia

Todo consumidor de eventos debe ser idempotente: procesar el mismo evento dos veces debe producir el mismo resultado que procesarlo una vez. Esta es una garantía que cada servicio debe implementar internamente, registrando los `eventId` procesados.

---

# PARTE IV — EL JOURNEY

---

## 9. Journey de un Proyecto

Este capítulo describe cronológicamente cómo un proyecto viaja a través de todo el ERP, desde el primer contacto comercial hasta el análisis post-evento. Es la síntesis práctica de todo el modelo de dominio.

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                     JOURNEY DE UN PROYECTO — VISIÓN COMPLETA                   ║
╚══════════════════════════════════════════════════════════════════════════════════╝

FASE 1: COMERCIAL                              [CRM Domain]
───────────────────────────────────────────────────────────

PASO 1: Lead entra al sistema
  Actor:   Asesor comercial
  Dominio: crm-service
  Evento:  LeadCreated
  Estado:  Lead → NUEVO

PASO 2: Calificación del lead
  Actor:   Asesor comercial
  Acción:  Valida que la oportunidad tiene potencial real
  Evento:  LeadQualified
  Estado:  Lead → CALIFICADO

PASO 3: Brief solicitado al cliente
  Actor:   Asesor comercial
  Acción:  El cliente envía los requisitos del evento
  Nota:    El brief puede ser un documento adjunto o un formulario

PASO 4: Propuesta enviada
  Actor:   Asesor comercial + Director
  Evento:  LeadProposalSent
  Estado:  Lead → PROPUESTA

PASO 5: Negociación
  Actor:   Asesor comercial
  Estado:  Lead → NEGOCIACIÓN

PASO 6A: Lead perdido
  Evento:  LeadLost
  Fin del journey para este lead

PASO 6B: Deal ganado ← PUNTO DE INFLEXIÓN
  Actor:   Director comercial (aprueba)
  Evento:  DealWon { dealId, clientId, brandCodes, estimatedValue, eventDate }
  ─────────────────────────────────────────────────────────────────────────────
  ANTI-CORRUPTION LAYER: El dominio comercial termina aquí.
  El evento DealWon cruza la frontera hacia el dominio operacional.
  Un "Deal" en CRM nunca es igual a un "Project" en Operations.
  El modelo del CRM no contamina el modelo operacional.
  ─────────────────────────────────────────────────────────────────────────────


FASE 2: INICIALIZACIÓN                         [Project Domain]
────────────────────────────────────────────────────────────────

PASO 7: Proyecto creado
  Actor:   project-service (automático, consume DealWon)
  Acción:  Traduce el Deal a un Project con su propio modelo
  Evento:  ProjectCreated
  Estado:  Proyecto → BRIEF_RECEIVED
  Nota:    Se asigna un Coordinador de Proyecto

PASO 8: Departamentos vinculados
  Actor:   Coordinador de Proyecto
  Acción:  Identifica qué departamentos participan en este proyecto
  Evento:  ProjectDepartmentLinked (uno por cada dept)
  Efecto:  notification-service envía email al líder de cada dept

PASO 9: Timeline establecido
  Actor:   Coordinador de Proyecto
  Acción:  Define fechas clave: evento, instalación, pre-producción
  Evento:  TimelineUpdated

PASO 10: Budget inicial definido
  Actor:   Director comercial
  Evento:  BudgetCreated
  Dominio: financial-service recibe el presupuesto comprometido con el cliente


FASE 3: DISEÑO CREATIVO                        [Project + Order Domain]
────────────────────────────────────────────────────────────────────────

PASO 11: Brief enviado al equipo creativo
  Actor:   Coordinador de Proyecto
  Evento:  ProjectBriefSubmitted
  Estado:  Proyecto → IN_DESIGN
  Efecto:  operations-service crea WorkOrder para departamento CREATIVE

PASO 12: Desarrollo del concepto
  Actor:   Equipo creativo
  Acción:  Desarrolla mood board, renders, presentación
  Nota:    Los archivos se suben via media-service, referenciados en el proyecto

PASO 13: Concepto presentado al cliente
  Actor:   Coordinador + Creativo
  Nota:    Este paso ocurre fuera del sistema (reunión); el resultado se registra

PASO 14A: Concepto rechazado
  Actor:   Coordinador
  Acción:  Se registra el rechazo con observaciones
  Estado:  Proyecto → IN_DESIGN (iteración)
  ↻ Volver al paso 12

PASO 14B: Concepto aprobado
  Actor:   Coordinador
  Evento:  ProjectBriefApproved → ProjectCreativeApproved
  Estado:  Proyecto → APPROVED
  Efecto:  notification-service notifica a todos los líderes de dept
           operations-service habilita creación de órdenes de producción


FASE 4: PLANIFICACIÓN                          [Order + Inventory + Marketplace Domain]
──────────────────────────────────────────────────────────────────────────────────────

PASO 15: Cada departamento crea su Work Order
  Actor:   Líder de cada departamento
  Dominio: operations-service
  Evento:  OrderCreated (uno por dept)
  Nota:    Una orden contiene líneas que especifican qué se necesita

PASO 16: Por cada línea de la orden, se decide el origen del recurso:

  OPCIÓN A — Activo propio de inventario
    Dominio: inventory-service verifica disponibilidad
    Resultado OK → AssetReserved
    Resultado FAIL → AssetUnavailableForReservation → Coordinador decide alternativa

  OPCIÓN B — Fabricación interna (Custom X, Swag)
    Dominio: operations-service crea orden de fabricación
    Estado de línea: EN_FABRICACIÓN

  OPCIÓN C — Recurso externo (Marketplace)
    Evento: OrderLineExternalRequested
    Dominio: marketplace-service identifica proveedor
    Proceso: cotización, contratación, confirmación
    Evento: VendorContracted → financial-service registra costo comprometido

PASO 17: Órdenes confirmadas
  Actor:   Coordinador o líderes de dept
  Evento:  OrderConfirmed (por orden)
  Estado:  Proyecto → IN_PRODUCTION


FASE 5: PRODUCCIÓN                             [Order + Inventory Domain]
──────────────────────────────────────────────────────────────────────────

PASO 18: Fabricación interna en proceso
  Actor:   Custom X / Swag
  Acción:  Fabrican elementos custom para el proyecto
  Evento:  (estado de línea de orden actualizado)

PASO 19: Activos preparados en bodega
  Actor:   Operador de bodega
  Acción:  Activos físicos son revisados, marcados y agrupados por dispatch
  Dominio: inventory-service

PASO 20: Recursos externos confirmados
  Actor:   Proveedor + Coordinador de Marketplace
  Evento:  ResourceDelivered (cuando aplica)


FASE 6: DESPACHO Y LOGÍSTICA                   [Order + Logistics Domain]
──────────────────────────────────────────────────────────────────────────

PASO 21: Dispatch planeado
  Actor:   Coordinador de logística
  Dominio: operations-service crea Dispatch record
  Evento:  DispatchScheduled
  Efecto:  logistics-service recibe el plan y optimiza rutas

PASO 22: Despacho ejecutado
  Actor:   Equipo de logística
  Evento:  DispatchStarted
  Estado:  Proyecto → DISPATCHED
  Efecto:  inventory-service marca activos como EN_TRÁNSITO

PASO 23: Llegada al destino
  Evento:  DispatchCompleted
  Efecto:  inventory-service marca activos como EN_SITIO


FASE 7: EVENTO                                 [Project Domain]
────────────────────────────────────────────────────────────────

PASO 24: Setup en sitio
  Actor:   Equipo en campo
  Estado:  Proyecto → ON_SITE

PASO 25: El evento ocurre
  Estado:  Proyecto → EVENT_DAY
  Nota:    El sistema puede usarse para check-lists y registro de incidencias en campo

PASO 26: Tear-down
  Actor:   Equipo en campo
  Estado:  Proyecto → RETURNING


FASE 8: RETORNO E INVENTARIO                   [Inventory Domain]
──────────────────────────────────────────────────────────────────

PASO 27: Activos retornan al warehouse
  Actor:   Operador de bodega
  Dominio: operations-service registra retorno
  Evento:  OrderReturned

PASO 28: Inspección de activos
  Actor:   Operador de bodega
  Para cada activo:
    Sin daño → AssetReleased → activo disponible nuevamente
    Con daño → AssetDamaged → AssetSentToMaintenance
               financial-service registra costo estimado de reparación

PASO 29: Retorno completo confirmado
  Evento:  OrderReturnCompleted
  Estado:  Proyecto → RETURNED


FASE 9: CIERRE FINANCIERO                      [Financial Domain]
──────────────────────────────────────────────────────────────────

PASO 30: Reconciliación de costos
  Actor:   Área financiera
  Dominio: financial-service
  Acción:  Compara presupuesto vs costos reales incurridos
  Evento:  CostIncurred (para cada costo final)

PASO 31: Facturación
  Actor:   Área financiera
  Evento:  InvoiceGenerated
  Efecto:  notification-service envía factura al cliente

PASO 32: Pago recibido
  Evento:  PaymentReceived
  Estado:  Proyecto → CLOSED
  Evento:  ProjectClosed


FASE 10: ANALÍTICA                             [Analytics Domain]
──────────────────────────────────────────────────────────────────

PASO 33: Analytics actualiza read models
  Actor:   analytics-service (automático, consume ProjectClosed)
  Calcula: ROI del proyecto, utilización de activos, desviación de presupuesto,
           satisfacción del cliente, tiempo entre fases, métricas por departamento

PASO 34: Reportes disponibles
  Actor:   Director, Coordinadores
  Dominio: analytics-service
  Vista:   Dashboard de proyectos cerrados, KPIs por periodo, tendencias
```

---

# PARTE V — LA ARQUITECTURA TÉCNICA

---

## 10. Diagnóstico de la Arquitectura Actual

> Esta sección es crítica. Describe el estado real del sistema hoy, los problemas que existen, y las decisiones correctivas que se han tomado.

### 10.1 ⚠️ core-inventory es un monolito disfrazado de microservicio

El gateway actual enruta 11 de sus 13 rutas hacia el mismo servicio. Ese servicio gestiona proyectos, órdenes, inventario, CRM, analytics, mantenimiento, departamentos, uploads y más.

Esto no es arquitectura de microservicios. Es un monolito con un nombre diferente.

**Consecuencias concretas:**
- Un query analítico lento bloquea conexiones de la pool de Hibernate y degrada los proyectos
- Un bug en el módulo de uploads puede tirar abajo el módulo de proyectos
- No existe deployment independiente por dominio
- El equipo no puede trabajar en paralelo sin conflictos de merge
- Viola el principio P3 (dominios, no módulos en un proceso)

**Decisión:** Extraer gradualmente en servicios por dominio. El proceso es incremental, no un big bang. Ver Hoja de Ruta.

### 10.2 ⚠️ Kafka configurado pero completamente inactivo

Los servicios se comunican exclusivamente por REST síncrono. Si `notifications` está caído, el proceso de notificación de departamentos falla sin posibilidad de reintento.

**Decisión:** Kafka debe activarse con consumidores reales o retirarse de la configuración. No existe una posición intermedia operacionalmente válida. Ver ADR-004.

### 10.3 ⚠️ Datos del CRM en localStorage del navegador

Los deals, contactos, actividades y pipeline del CRM viven en el navegador. Un usuario que limpia el caché pierde todo su pipeline. Dos comerciales no pueden ver el trabajo del otro. No es posible construir analytics sobre datos de CRM reales.

**Decisión:** Migración completa a crm-service con base de datos. Ver ADR-002.

### 10.4 ⚠️ Archivos servidos desde el servidor de aplicación

Spring Boot sirviendo archivos estáticos desde disco impide múltiples réplicas del servicio. El sistema de archivos no está compartido.

**Decisión:** Migrar a media-service con MinIO como backend de object storage. Ver ADR-005.

### 10.5 ⚠️ El dominio Financiero está ausente

No existe un servicio ni un módulo claro que gestione presupuestos, costos reales, facturación y cobros. Esta responsabilidad está dispersa o simplemente no implementada.

**Decisión:** Definir financial-service como bounded context desde ahora. Ver ADR-008.

### 10.6 ⚠️ Estados de proyecto hardcodeados como enum

El enum `ProjectStatus` con 8 valores no refleja el flujo real del negocio. Cada cambio requiere un deploy.

**Decisión:** Tabla `project_states` con `project_phases`. Los colores de los estados se derivan interpolando dentro de la paleta de su fase. Ver ADR-006.

---

## 11. Catálogo de Servicios

### Clasificación de servicios

Cada servicio de Quantum pertenece a exactamente una categoría. La categoría determina qué principios aplican, qué métricas de calidad son relevantes y cómo evoluciona el servicio.

```
Platform Services      Foundation Services    Business Engines
───────────────────    ────────────────────   ────────────────
gateway                project-service        inventory-service ✅
identity-service ✅    calendar-service       crm-service
platform-runtime ✅    document-service       creative-service
notification-service   organization-service   manufacturing-service
audit-service          workflow-service       service-service
configuration-service
```

| | P/S | F/S | B/E |
|---|:---:|:---:|:---:|
| Implementa P-PLT | ✓ | | |
| Implementa P-FND | | ✓ | |
| Implementa P-ENG | | | ✓ |
| Tiene Capabilities | | | ✓ |
| Tiene Business Contract | | | ✓ |
| Participa en Blueprints | | | ✓ |
| Su falla afecta toda la plataforma | ✓ | | |
| Consumible por cualquier Engine | | ✓ | |

---

### Criterio de selección tecnológica

La tecnología de cada servicio se selecciona según la naturaleza de su dominio, no por preferencia del equipo:

| Criterio | Spring Boot (Kotlin) | NestJS (TypeScript) |
|---|---|---|
| Transacciones ACID complejas entre múltiples entidades | ✅ Óptimo | ⚠️ Posible, requiere mayor disciplina |
| Lógica de negocio con muchas invariantes | ✅ Type-safe, refactorable con compilador | ⚠️ Funciona, mayor superficie de error en runtime |
| Migraciones de esquema con Flyway | ✅ Ecosistema maduro y consolidado | ⚠️ Posible pero con más configuración |
| Integraciones con APIs externas y webhooks | ⚠️ Verboso | ✅ Más ágil |
| Procesamiento ligero de eventos | ✅ | ✅ |
| Servicios auxiliares sin lógica transaccional compleja | ⚠️ Overhead de ~200-400MB y startup ~10s | ✅ ~80-150MB, startup ~2s |

**Regla:** Spring Boot para los dominios transaccionales críticos. NestJS para servicios auxiliares, integraciones, y procesamiento de eventos.

---

### gateway — Spring Boot Cloud Gateway

**Categoría:** Platform Service — P-PLT

**Dominio que representa:** Punto de entrada único al sistema. No representa ningún dominio de negocio.

**Responsabilidad exclusiva:** Routing, autenticación JWT, rate limiting, circuit breakers, CORS. Nada más.

**Lo que nunca debe hacer:** Contener lógica de negocio. Transformar datos. Tomar decisiones sobre el negocio. Si en algún momento hay lógica de negocio en el gateway, es un error de arquitectura.

**Estado actual:** ✅ Bien definido. Circuit breakers con Resilience4j. Rate limiting con Redis. Requiere actualizar rutas a medida que se extraen servicios de core-inventory.

---

### identity-service — Spring Boot

**Categoría:** Platform Service — P-PLT

**Principios que aplican:** P-PLT-001 (Zero Trust), P-PLT-002 (Stateless), P-PLT-003 (Identidad de Servicio), P-PLT-004 (Plataforma Opaca), P-PLT-005 (Alta Disponibilidad)

**No aplica:** P-ENG. Identity Service nunca tendrá Capabilities, Contracts ni Blueprint. Su excelencia se mide con métricas propias: disponibilidad, latencia de verificación, tiempo de revocación efectiva, cobertura de test de identidad.

**Dominio que representa:** Identidad y Acceso.

**Entidades que controla:** User, Role, Permission, Session, OAuthAccount.

**Datos que posee:** Credenciales, tokens, asignaciones de roles.

**Capacidades expuestas:** Autenticación con email/password, OAuth2 con Google, emisión de JWT, gestión de usuarios y roles.

**Eventos que publica:** `UserCreated`, `UserDeactivated`, `RoleAssigned`.

**Eventos que consume:** Ninguno.

**Lo que nunca debe hacer:** Saber sobre proyectos, órdenes, departamentos ni cualquier entidad de negocio. Si identity-service necesita saber que "el usuario Juan es líder del departamento CEL", ese conocimiento pertenece a project-service (que almacena ProjectMember), no a identity-service.

**Pendiente:** Agregar soporte para roles por departamento (un usuario puede ser ADMIN en CEL y VIEWER en CUS).

---

### project-service — Spring Boot

**Categoría:** Foundation Service — P-FND

**Principios que aplican:** P-FND-001 (Dominio Transversal), P-FND-002 (API como Contrato Estable), P-FND-003 (Sin Lógica de Engine), P-FND-004 (Consumible por Cualquier Engine)

**No aplica:** P-ENG. Project Service nunca tendrá Capabilities ni Business Contract. Su excelencia se mide por: estabilidad de API, cobertura de dominio (hasta qué punto modela completamente el ciclo de vida de un proyecto), y facilidad de consumo por parte de cualquier Engine. La ruta de evolución es hacia Foundation Service completo: Milestones, Timelines, Dependencias, Risks, Deliverables, Workflow de aprobaciones.

**Dominio que representa:** Proyectos. El núcleo del sistema.

**Entidades que controla:** Project, ProjectState (catálogo), ProjectPhase (catálogo), ProjectMember, Timeline, Department (configuración), CostCenter, Brief.

**Datos que posee:** Todo lo relacionado con la existencia y el ciclo de vida de un proyecto.

**Capacidades expuestas:** CRUD de proyectos, gestión de estados y transiciones, asignación de departamentos y miembros, configuración de departamentos y estados.

**Eventos que publica:** `ProjectCreated`, `ProjectStateChanged`, `ProjectDepartmentLinked`, `ProjectBriefSubmitted`, `ProjectBriefApproved`, `ProjectCreativeApproved`, `ProjectStandBy`, `ProjectCancelled`, `ProjectClosed`, `TimelineUpdated`.

**Eventos que consume:** `DealWon` (para crear el proyecto desde el CRM).

**Lo que nunca debe hacer:** Gestionar activos físicos, crear facturas, optimizar rutas, enviar emails directamente, o almacenar datos del CRM.

---

### operations-service — Spring Boot

**Dominio que representa:** Órdenes de trabajo y despacho.

**Entidades que controla:** WorkOrder, OrderLine, Dispatch, BrandOrderConfirmation.

**Datos que posee:** Toda la operativa de qué se necesita, cuándo y para qué proyecto.

**Capacidades expuestas:** Creación y gestión de Work Orders por departamento, gestión de líneas de orden, programación y registro de despachos.

**Eventos que publica:** `OrderCreated`, `OrderConfirmed`, `OrderLineExternalRequested`, `DispatchScheduled`, `DispatchStarted`, `DispatchCompleted`, `OrderReturned`, `OrderReturnCompleted`.

**Eventos que consume:** `ProjectStateChanged` (para habilitar o bloquear operaciones según el estado del proyecto), `AssetReserved` (para confirmar disponibilidad), `VendorContracted` (para confirmar líneas externas).

**Lo que nunca debe hacer:** Reservar activos directamente (eso es inventory-service), contratar proveedores directamente (eso es marketplace-service), ni modificar el estado de un proyecto (eso es project-service).

---

### inventory-service — Spring Boot ✅ MVP COMPLETO

**Categoría:** Business Engine — P-ENG

**Principios que aplican:** P-ENG-001 a P-ENG-007, P-ARC-001 (Anti-Complejidad), P-ARC-002 (Dominio-Ignorante)

**Dominio que representa:** Inventario y activos físicos.

**Entidades que controla:** Asset, AssetIdentifier, Reservation, Inspection, Kit, KitItem, AssetStateChange, AuditEntry, MaintenanceRecord.

**Datos que posee:** El catálogo de activos, el estado físico de cada unidad, el historial de operaciones y mantenimiento.

**12 Capabilities implementadas:** `asset_registry`, `assignment`, `transfer`, `reservation`, `inspection`, `lifecycle`, `barcode`, `rfid`, `kits`, `audit`, `maintenance`, `batch`.

**Contract:** `inventory-v1` — expone las 12 capabilities al Platform Runtime.

**Eventos que publica (15):** `AssetRegistered`, `AssetUpdated`, `AssetDeactivated`, `AssetAssigned`, `AssetReleased`, `AssetTransferred`, `AssetReserved`, `ReservationCancelled`, `AssetActivated`, `AssetDecommissioned`, `BarcodeScanned`, `RFIDDetected`, `KitAssembled`, `KitDisassembled`, `MaintenanceScheduled`, `MaintenanceCompleted`, `BatchRegistered`, `BatchTransferred`.

**Endpoint de registro:** `GET /engine/manifest` — retorna todas las capabilities y contracts. El Platform Runtime lo consume en startup.

**Lo que nunca debe hacer:** Contener lógica específica de KeepMe o Celebrate. Usar `if/switch` basados en nombre de módulo. Llamar directamente a otro Engine. Gestionar proyectos, crear órdenes, procesar pagos.

---

### platform-runtime — Spring Boot ✅ MVP COMPLETO

**Categoría:** Platform Service — P-PLT

**Principios que aplican:** P-PLT-001 a P-PLT-005, P-ARC-002 (Dominio-Ignorante)

**Dominio que representa:** Ninguno. El Platform Runtime es infraestructura pura de orquestación.

**Responsabilidad exclusiva:** Descubrir Business Engines, registrar sus capabilities y contracts, validar el grafo de dependencias, compilar Blueprint declarations, y enrutar ejecuciones al Engine correcto.

**8 componentes implementados:**

| Componente | Clase | Responsabilidad |
|---|---|---|
| EngineRegistry | `registry/EngineRegistry` | Registro en memoria de Engines registrados |
| CapabilityRegistry | `registry/CapabilityRegistry` | Índice de CapabilityDescriptors por Engine |
| ContractRegistry | `registry/ContractRegistry` | Índice de ContractDescriptors por Engine |
| ModuleRegistry | `registry/ModuleRegistry` | Registro de Modules instalados (YAML → ACTIVE) |
| RuntimeLoader | `loader/RuntimeLoader` | Llama a `GET /engine/manifest` de cada Engine configurado |
| BlueprintCompiler | `compiler/BlueprintCompiler` | Valida Blueprint declarations contra capabilities registradas |
| ModuleInstaller | `installer/ModuleInstaller` | Instala un Blueprint compilado como Module ACTIVE |
| EngineDispatcher | `dispatcher/EngineDispatcher` | Enruta ejecuciones al Engine correcto vía HTTP |

**Descubrimiento de Engines:** configuración estática en `application.yml` (`quantum.runtime.engines.<engineId>: <baseUrl>`). El loader llama `GET {baseUrl}/engine/manifest` en `ApplicationReadyEvent`.

**API expuesta:** `GET /runtime/engines`, `GET /runtime/engines/{id}`, `GET /runtime/engines/{id}/capabilities`, `GET /runtime/engines/{id}/contracts`, `GET /runtime/modules`, `POST /runtime/modules`.

**Lo que nunca debe hacer:** Contener lógica de dominio de negocio. Importar clases de `inventory-service` ni de cualquier Engine. Conocer los conceptos de KeepMe, Celebrate, activos, proyectos ni cualquier entidad de negocio.

**Puerto:** 8090.

---

### entity-registry — NestJS

**Dominio que representa:** Registro de entidades con esquema dinámico.

**Entidades que controla:** EntityType, EntityFieldDefinition, EntityInstance.

**Datos que posee:** La definición de todos los tipos de entidad dinámica (Vehículo, Speaker, Venue, etc.) y sus instancias.

**Capacidades expuestas:** CRUD de tipos de entidad y sus definiciones de campo, CRUD de instancias, búsqueda y filtrado por atributos.

**Eventos que publica:** `EntityCreated`, `EntityUpdated`, `EntityDecommissioned`.

**Eventos que consume:** Ninguno.

**Lo que nunca debe hacer:** Gestionar activos físicos individuales con trazabilidad (eso es inventory-service), ni almacenar entidades de negocio core como proyectos o usuarios.

---

### crm-service — NestJS

**Dominio que representa:** CRM. La relación comercial con clientes.

**Entidades que controla:** Lead, Deal, Client (Company desde perspectiva comercial), Contact, Activity, Ticket, Task.

**Datos que posee:** Todo el pipeline comercial y la historia de relación con cada cliente.

**Capacidades expuestas:** Pipeline CRUD, gestión de leads y deals, registro de actividades, gestión de contactos.

**Eventos que publica:** `LeadCreated`, `LeadQualified`, `LeadWon`, `LeadLost`, `DealWon`, `DealLost`.

**Eventos que consume:** Ninguno.

**Lo que nunca debe hacer:** Crear proyectos directamente (publica el evento, project-service crea el proyecto), acceder a datos del inventario, ni gestionar activos.

**Migración crítica:** Todo lo que hoy está en localStorage debe migrar a la base de datos de crm-service. Ver ADR-002.

---

### creative-service — NestJS

**Dominio que representa:** Diseño creativo. La producción intelectual y visual del proyecto.

**Entidades que controla:** CreativeBrief, CreativeAsset, DesignVersion, ApprovalRequest, DesignReview, Blueprint, Render.

**Datos que posee:** Todo el historial de trabajo creativo de un proyecto: los activos producidos, sus versiones, los ciclos de revisión y el estado de aprobación.

**Capacidades expuestas:** CRUD de activos creativos y sus versiones, gestión de solicitudes de aprobación, registro de revisiones, vinculación de entregables a proyectos.

**Eventos que publica:** `CreativeAssetCreated`, `DesignVersionSubmitted`, `ApprovalRequested`, `DesignApproved`, `DesignRejected`, `DesignRevisionRequested`.

**Eventos que consume:** `ProjectBriefSubmitted` (para iniciar el proceso creativo sobre un proyecto), `ProjectCancelled` (para archivar activos creativos sin aprobación final).

**Relación con project-service:** Cuando creative-service emite `DesignApproved`, project-service consume ese evento y ejecuta la transición de estado `ProjectCreativeApproved`. El estado del proyecto lo controla project-service; el estado del diseño lo controla creative-service. Son dos máquinas de estado distintas.

**Lo que nunca debe hacer:** Gestionar activos físicos, crear órdenes de trabajo, acceder a inventario, ni modificar el estado de un proyecto directamente.

**Por qué NestJS:** creative-service es mayoritariamente CRUD sobre activos y versiones, con flujos de aprobación relativamente simples. No tiene transacciones ACID complejas entre múltiples entidades relacionadas. NestJS con TypeORM es adecuado y su menor footprint de memoria es relevante para un servicio de alta lectura.

---

### marketplace-service — NestJS

**Dominio que representa:** Contratación de recursos externos.

**Entidades que controla:** Vendor (Company desde perspectiva de proveedor), Contract, ExternalResource.

**Datos que posee:** Directorio de proveedores, contratos vigentes y cerrados, recursos externos por proyecto.

**Capacidades expuestas:** Directorio de proveedores, creación y gestión de contratos, registro de entrega de recursos.

**Eventos que publica:** `VendorContracted`, `ContractAmended`, `ResourceDelivered`, `ContractClosed`.

**Eventos que consume:** `OrderLineExternalRequested` (para iniciar el proceso de contratación).

**Lo que nunca debe hacer:** Gestionar activos propios de Brandex, crear proyectos, ni procesar pagos al cliente.

**Nota sobre implementación:** A la escala actual del sistema, marketplace-service puede comenzar como un módulo dentro de operations-service, con una separación clara de responsabilidades que permita extraerlo más adelante. La decisión de implementarlo como servicio independiente desde el inicio debe estar justificada por la complejidad operacional del proceso de contratación. Ver ADR-009.

---

### financial-service — NestJS

**Dominio que representa:** Control financiero de proyectos.

**Entidades que controla:** Budget, BudgetLine, ActualCost, Invoice, Payment.

**Datos que posee:** El presupuesto de cada proyecto y su estado de ejecución real.

**Capacidades expuestas:** Gestión de presupuestos, registro de costos reales, generación de facturas, registro de pagos, reportes financieros por proyecto.

**Eventos que publica:** `BudgetCreated`, `BudgetAdjusted`, `CostIncurred`, `InvoiceGenerated`, `PaymentReceived`.

**Eventos que consume:** `ProjectCreated` (para crear presupuesto inicial), `OrderConfirmed` (para registrar costo comprometido), `VendorContracted` (para registrar costo externo comprometido), `AssetDamaged` (para registrar costo de reparación), `ProjectClosed` (para calcular cierre financiero).

**Lo que nunca debe hacer:** Aprobar transiciones de estado de proyectos, gestionar activos, ni comunicarse directamente con el cliente.

**Nota:** Este servicio está ausente en la arquitectura actual. Es el gap más importante a resolver después de la separación de core-inventory.

---

### notification-service — NestJS

**Dominio que representa:** Comunicaciones disparadas por eventos.

**Entidades que controla:** Template, SendLog, DeliveryStatus.

**Datos que posee:** Templates de mensajes, historial de envíos.

**Capacidades expuestas:** Envío de emails, gestión de templates, consulta de logs de entrega.

**Eventos que publica:** `NotificationDelivered`, `NotificationFailed`.

**Eventos que consume:** Prácticamente cualquier evento del sistema que requiera comunicación: `ProjectDepartmentLinked`, `ProjectStateChanged`, `OrderConfirmed`, `DispatchStarted`, `InvoiceGenerated`, `AssetDamaged`, y más.

**Lo que nunca debe hacer:** Tener iniciativa propia. Nunca decide cuándo enviar una notificación: siempre responde a un evento. Nunca modifica datos de negocio.

---

### analytics-service — NestJS

**Dominio que representa:** Inteligencia operacional.

**Entidades que controla:** Read models propios (proyecciones desnormalizadas optimizadas para consulta).

**Datos que posee:** Proyecciones de eventos consumidos, pre-calculadas para consulta eficiente.

**Capacidades expuestas:** Dashboards por departamento, KPIs por periodo, ROI por proyecto, métricas de utilización de activos, análisis de pipeline comercial.

**Eventos que publica:** Ninguno.

**Eventos que consume:** Todos los eventos relevantes de todos los dominios para mantener sus read models actualizados.

**Lo que nunca debe hacer:** Escribir en las bases de datos de otros servicios, ni servir como fuente de verdad para operaciones de negocio. Sus datos son eventualmente consistentes y están optimizados para lectura, no para escritura transaccional.

---

### media-service — NestJS

**Dominio que representa:** Gestión de archivos y documentos.

**Entidades que controla:** FileMetadata, Bucket.

**Datos que posee:** Metadata de archivos (nombre, tipo, tamaño, bucket, URL, entidad a la que pertenece).

**Backend de almacenamiento:** MinIO (self-hosted, S3-compatible).

**Capacidades expuestas:** Upload de archivos, obtención de URLs, eliminación, categorización por tipo de entidad.

**Eventos que publica:** `DocumentUploaded`.

**Eventos que consume:** Ninguno.

**Lo que nunca debe hacer:** Servir archivos directamente a través del servidor de aplicación en producción. Los archivos se sirven directamente desde MinIO o a través de un CDN.

---

### currency-service — NestJS — EXISTENTE

**Dominio que representa:** Moneda interna y wallets.

**Entidades que controla:** Wallet, QPoint, Transaction.

**Estado actual:** ✅ Bien definido. Mantener.

---

### logistics-service — NestJS — EXISTENTE

**Dominio que representa:** Optimización de rutas logísticas.

**Entidades que controla:** RouteOptimization, DeliveryWindow.

**Estado actual:** ✅ Bien definido. Mantener.

**Eventos que consume:** `DispatchScheduled` (para calcular rutas óptimas).

---

## 12. Arquitectura de Datos

### Propiedad de datos por servicio

```
identity-service         → auth_db         (users, roles, permissions, sessions)
project-service      → project_db      (projects, states, phases, departments, members)
operations-service        → order_db        (work_orders, order_lines, dispatches)
inventory-service    → inventory_db    (assets, stock, maintenance, assignments)
crm-service          → crm_db          (leads, deals, contacts, activities, tasks)
entity-registry      → entity_db       (types, field_definitions, instances)
marketplace-service  → marketplace_db  (vendors, contracts, resources)
financial-service    → financial_db    (budgets, costs, invoices, payments)
analytics-service    → analytics_db    (read models, aggregations)
notification-service→ notifications_db(templates, send_log)
media-service        → media_db        (file_metadata, buckets)
currency-service     → currency_db     (wallets, transactions)
```

**Regla absoluta:** Ningún servicio tiene credenciales de la base de datos de otro servicio. La comunicación entre servicios es exclusivamente a través de APIs y eventos.

### Infraestructura física de datos

Un único servidor PostgreSQL con bases de datos lógicas separadas satisface los requerimientos actuales. La separación lógica garantiza el principio de aislamiento. La separación física (servidor dedicado por servicio) es una evolución para cuando el volumen lo justifique.

Cada servicio tiene su propio usuario de PostgreSQL con permisos exclusivos sobre su base de datos.

### Estados de proyecto — Modelo configurable

Los estados de proyecto dejan de ser un enum en el código. Son datos almacenados en la base de datos de project-service:

**Fases** (las 4 grandes etapas):
- Cada fase tiene un código, nombre, color base y color pico
- Los proyectos STAND_BY y CANCELLED son fases transversales que pueden activarse desde cualquier punto

**Estados** (los 13 estados individuales):
- Cada estado pertenece a una fase
- Tiene un orden dentro de la fase (determina la intensidad del color por interpolación)
- Define explícitamente qué transiciones están permitidas
- Puede requerir un rol específico para la transición

**El color de cada estado se calcula, no se almacena:**
```
color = interpolate(phase.colorBase, phase.colorPeak, state.sortOrder / maxSortInPhase)
```

El frontend renderiza el color dinámicamente. Agregar un nuevo estado no requiere cambiar el frontend.

### Identificadores

- Todas las entidades expuestas en APIs usan **UUID v4** como identificador
- Las tablas de eventos de alta inserción (audit_log, state_history) pueden usar BIGSERIAL para ordenamiento eficiente

---

## 13. Comunicación entre Servicios

### Cuándo usar REST síncrono vs eventos asíncronos

| Situación | Mecanismo recomendado |
|---|---|
| Necesito la respuesta para continuar el flujo del usuario | REST síncrono |
| Verifico disponibilidad de un recurso antes de confirmar | REST síncrono |
| Notifico que algo ocurrió y no necesito la respuesta | Evento asíncrono |
| Actualizo analytics, historial, o envío notificaciones | Evento asíncrono |
| Necesito que múltiples servicios reaccionen al mismo hecho | Evento asíncrono (fan-out) |
| Dos servicios deben coordinar una operación distribuida | Saga pattern con eventos |

### Decisión sobre el message broker — ADR-004

Kafka está configurado pero inactivo. Esta situación no es sostenible.

**Opción A — Activar Kafka:**
Mayor capacidad, replay de eventos, alta durabilidad. Costo: operación de un sistema distribuido adicional.

**Opción B — Redis Streams:**
Redis ya está en producción para rate limiting. Redis Streams ofrece semántica similar a Kafka para los volúmenes de este sistema. Menor overhead operacional.

**Recomendación:** Redis Streams a corto plazo. Kafka cuando el volumen de eventos supere 10,000/día o cuando se requieran consumidores multi-region. La decisión final está en ADR-004.

### Comunicación interna segura

Las llamadas REST directas entre servicios (para consultas síncronas) usan el header `X-Service-Key`. El tráfico interno nunca pasa por el gateway público.

---

## 14. Estándares de API

### Principios de diseño

Toda API del sistema sigue estos principios, sin excepciones:

**Orientada a recursos:** Los endpoints representan sustantivos (entidades), no verbos (acciones). Las acciones se expresan como sub-recursos o transiciones.

```
✅ POST /projects/{id}/state-transitions
❌ POST /projects/changeState
```

**Versionada:** Toda API pública lleva versión en la URL. `/api/v1/...`

**Contratos explícitos:** Toda API tiene un spec OpenAPI publicado. El spec es la fuente de verdad del contrato, no la implementación.

**Errores uniformes:** Todos los servicios retornan errores en la misma estructura, con un código de error de negocio (no solo el HTTP status), un mensaje humano y el correlationId para trazabilidad.

**Paginación consistente:** Todas las listas usan el mismo esquema de paginación con `data`, `total`, `page` y `pageSize`.

### Versionado y deprecación

Cuando un endpoint cambia su contrato de manera incompatible:
1. La nueva versión se publica en `/api/v2/...`
2. La versión anterior se mantiene operativa por 90 días con header de deprecación
3. La migración se documenta en el CHANGELOG
4. Después de 90 días, la versión anterior se retira

---

# PARTE VI — LA PLATAFORMA

---

## 15. Arquitectura del Frontend

### Principio fundamental

La experiencia visual del usuario no cambia. Los componentes actuales, la estética y el UX se mantienen. Lo que evoluciona es la organización interna del código y la fuente de datos (APIs reales en lugar de mocks o localStorage).

### Estructura de módulos

```
src/
│
├── router/
│     AppRouter.tsx           ← Definición de rutas + lazy loading
│     guards/                 ← Route guards por rol y permiso
│
├── layouts/
│     AppShell.tsx            ← Sidebar + topbar + content area
│     AuthLayout.tsx          ← Pantallas de login/registro
│     PrintLayout.tsx         ← Para documentos imprimibles
│
├── features/                 ← Un directorio por feature de negocio
│     projects/
│       components/           ← Componentes privados del feature
│       hooks/                ← Hooks de datos del feature
│       ProjectListPage.tsx
│       ProjectDetailPage.tsx
│       WorkOrderPage.tsx
│       index.ts              ← API pública del feature
│     crm/
│       components/
│       hooks/
│       CrmPipelinePage.tsx
│       index.ts
│     inventory/
│     orders/
│     marketplace/
│     analytics/
│     admin/
│
├── widgets/                  ← Bloques reutilizables con conciencia de negocio
│     NotificationBell.tsx    ← Sabe de notificaciones
│     DeptStatusChip.tsx      ← Sabe de departamentos
│     ProjectStateTag.tsx     ← Sabe de estados de proyecto
│     AssetAvailabilityBadge.tsx
│
├── components/               ← Componentes UI puros, sin conciencia de negocio
│     Button, Modal, Table, Card, Badge, Input, Select, DatePicker...
│     DynamicFieldRenderer.tsx ← Switch sobre field_type, sin if(entityType)
│     DynamicEntityForm.tsx
│
├── hooks/                    ← Hooks compartidos entre features
│     useAuth.ts
│     usePermissions.ts
│     useDeptConfig.ts        ← Carga configuración de departamentos desde API
│     useProjectStates.ts     ← Carga catálogo de estados desde API
│
├── services/                 ← Capa de comunicación con el backend
│     api/
│       apiClient.ts          ← Instancia axios con interceptors de auth
│       projectsApi.ts        ← Todas las funciones para project-service
│       ordersApi.ts
│       inventoryApi.ts
│       crmApi.ts
│       entityApi.ts
│       marketplaceApi.ts
│       financialApi.ts
│       analyticsApi.ts
│       mediaApi.ts
│     authService.ts          ← Login, logout, token refresh
│
├── store/                    ← Estado global de UI únicamente
│     authStore.ts            ← Zustand: usuario autenticado, token
│     uiStore.ts              ← Zustand: sidebar, preferencias
│
└── types/
      api.ts                  ← Tipos generados desde specs OpenAPI de cada servicio
      domain.ts               ← Tipos de dominio compartidos
```

### Estado del servidor vs estado de UI

| Tipo de estado | Herramienta | Ejemplos |
|---|---|---|
| Datos del servidor | TanStack Query | Proyectos, activos, deals, órdenes |
| Estado global de UI | Zustand | Usuario autenticado, modo sidebar, preferencias |
| Estado local de componente | useState / useReducer | Form fields, modal open/closed |
| Caché temporal | TanStack Query (automático) | Invalidación por tiempo o por mutación |

**localStorage** solo para:
- Preferencias de UI (modo oscuro, columnas visibles)
- Nunca para datos de negocio

### Formularios dinámicos

El `DynamicFieldRenderer` contiene un switch sobre `field_type`. Los tipos de campo son finitos y definidos en código. Lo que varía por tipo de entidad es la *configuración* que los campos reciben, nunca el tipo de renderer.

```
El frontend pregunta: ¿qué tipo de campo es este?
El frontend nunca pregunta: ¿qué tipo de entidad es esta?
```

### Lazy loading y routing

Cada feature module se carga de forma diferida (lazy). El usuario que solo usa CRM no descarga el código de Analytics ni de Inventario. La separación de bundles sigue la misma estructura que los feature modules.

---

## 16. Infraestructura y Despliegue

### Stack de servicios

```
SERVICIOS DE APLICACIÓN:
  gateway             (Spring Boot)   :8080
  identity-service        (Spring Boot)   :8081
  project-service     (Spring Boot)   :8082
  operations-service       (Spring Boot)   :8083
  inventory-service   (Spring Boot)   :8084
  crm-service         (NestJS)        :9001
  entity-registry     (NestJS)        :9002
  marketplace-service (NestJS)        :9003
  financial-service   (NestJS)        :9004
  notification-service (NestJS)      :9005
  media-service       (NestJS)        :9006
  analytics-service   (NestJS)        :9007
  currency-service    (NestJS)        :9008
  logistics-service   (NestJS)        :9009

INFRAESTRUCTURA:
  postgresql          base de datos relacional
  redis               rate limiting + (potencialmente) message broker
  minio               object storage para media
  zipkin              distributed tracing
```

### Branching y CI/CD

```
feature/* ──► master ──► main
                           │
                     GitHub Actions
                           │
                     Deploy producción
```

- `main` es producción. Solo `ces-bx` puede mergear. Cada push dispara el pipeline.
- `master` es integración. Las features se mergean aquí primero.
- Nuevas features: cortar desde `master`, no desde `main`.

### Health checks

Todo servicio expone endpoints de salud:
- **Liveness probe:** ¿el proceso está vivo?
- **Readiness probe:** ¿puede recibir tráfico? (BD conectada, dependencias críticas OK)

El gateway gestiona el circuit breaker: si un servicio no responde a su readiness probe, el gateway deja de enrutar tráfico hacia él y activa el fallback configurado.

---

## 17. Seguridad

### Capas de seguridad

```
Internet
   │
   ▼
Gateway ─── JWT validation ─── Si token inválido: 401 inmediato
   │    ─── Rate limiting  ─── Si excede límite: 429
   │    ─── Circuit breaker─── Si servicio caído: 503 con fallback
   │
   ▼
Servicio ─── Extrae claims del header X-Authenticated-User
         ─── Verifica que el usuario tiene permiso para esa operación específica
         ─── Ejecuta lógica de negocio
   │
   ▼
Base de datos ─── Usuario con permisos exclusivos sobre su BD
```

### Reglas de JWT

El gateway valida la firma del token y agrega el header `X-Authenticated-User` con los claims (userId, email, roles). Los servicios confían en ese header. Nunca vuelven a llamar a identity-service para validar el token en cada request.

Las llamadas directas entre servicios (síncronas) usan `X-Service-Key`. Nunca JWT entre servicios internos.

### Secretos

- Nunca en código fuente
- Nunca en git (`.gitignore` y `.dockerignore` cubren todos los patrones de secretos)
- En producción: GitHub Actions Secrets inyectados como variables de entorno
- Localmente: archivos `.env.local` (excluidos de git)
- Las API keys internas rotan cada 90 días

---

## 18. Observabilidad

### Los tres pilares

**Logs:** JSON estructurado con campos obligatorios `ts`, `level`, `correlationId`, `service`, `msg`. Nivel INFO en producción. Todo log debe ser legible por máquina para ingesta en ELK.

**Métricas:** Endpoint Prometheus en todos los servicios. Métricas de negocio: proyectos creados/hora, órdenes despachadas, deals ganados. Métricas técnicas: latencia p95/p99, error rate, tamaño de pool de conexiones.

**Trazas:** `correlationId` propagado en todos los headers entre servicios. Zipkin para visualizar el flujo distribuido de un request a través de múltiples servicios.

### Alertas mínimas requeridas

- Error rate > 5% sostenido en cualquier servicio crítico
- Latencia p95 > 2s en project-service u operations-service
- Health check fallido en cualquier servicio
- Pool de conexiones de BD > 80% de utilización
- Disk usage de MinIO > 80%
- Fallo de entrega de notificación para eventos críticos (ProjectStateChanged)

---

# PARTE VII — DECISIONES Y FUTURO

---

## 19. Decisiones Arquitectónicas (ADRs)

Los ADRs documentan las decisiones importantes con su contexto, la decisión tomada, las alternativas evaluadas y las consecuencias. Una decisión registrada en un ADR no se revierte sin crear un nuevo ADR que la reemplace.

---

### ADR-001: Separar core-inventory en servicios por dominio

**Estado:** Aceptado  
**Contexto:** core-inventory acumula 10+ responsabilidades distintas en un solo proceso. 11 de 13 rutas del gateway apuntan al mismo servicio.  
**Decisión:** Extraer gradualmente: project-service, operations-service, crm-service como prioridades. El proceso es incremental, con doble escritura temporal durante la transición.  
**Alternativa descartada:** Modularizar internamente el monolito. Descartada porque no resuelve el ciclo de deploy compartido ni los pools de conexión compartidos.  
**Riesgo:** Período de transición con complejidad elevada. Mitigado con feature flags y versioning de APIs.

---

### ADR-002: CRM migra de localStorage a base de datos

**Estado:** Aceptado  
**Contexto:** Todos los datos del CRM viven en el navegador. Pérdida de datos al limpiar caché. Sin visibilidad multi-usuario.  
**Decisión:** crm-service con PostgreSQL. Endpoint de importación para migración inicial desde localStorage.  
**Alternativa descartada:** Sincronización localStorage ↔ backend en background. Descartada por complejidad de resolución de conflictos.

---

### ADR-003: Departamentos y estados de proyecto en base de datos

**Estado:** Aceptado  
**Contexto:** Departamentos hardcodeados en frontend. Estados como enum en backend.  
**Decisión:** Tabla `department_config` en project-service. Tabla `project_states` + `project_phases`. Los colores de estado se interpolan dinámicamente.  
**Consecuencia:** El frontend necesita un fetch inicial de configuración. Justificado por la eliminación del ciclo deploy-por-configuración.

---

### ADR-004: Decisión sobre message broker

**Estado:** Aceptado  
**Contexto:** Kafka configurado pero inactivo. Servicios se comunican síncronamente.  
**Decisión:** Redis Streams.  
**Justificación:** Redis ya existe en producción como rate limiter del gateway. Cero overhead operacional adicional. Cubre el 100% de los casos de uso actuales. Semántica de grupos de consumidores, persistencia configurable y replay básico. Cuando el volumen supere los 10,000 eventos/día, se evalúa la migración a Kafka en un nuevo ADR.  
**Consecuencia:** La configuración de Kafka en `core-inventory/application.yml` debe ser eliminada para evitar confusión. El broker de producción es Redis Streams desde este momento.

---

### ADR-005: Archivos a object storage (MinIO)

**Estado:** Aceptado  
**Contexto:** Archivos servidos desde Spring Boot en disco local. Impide múltiples réplicas.  
**Decisión:** media-service con MinIO como backend.  
**Alternativa descartada:** S3 directamente. Descartada por costo y dependencia de proveedor cloud. MinIO permite migrar a S3 sin cambiar el código.

---

### ADR-006: Estados de proyecto en tabla configurable

**Estado:** Aceptado  
**Contexto:** Enum con 8 estados no refleja el flujo real de 13 estados en 4 fases.  
**Decisión:** Tablas `project_states` y `project_phases`. Transiciones configurables. Colores interpolados.  
**Consecuencia:** Los estados son data, no código. Cualquier cambio en el flujo es una migración de datos, no un deploy.

---

### ADR-007: Entity Registry con JSONB hybrid

**Estado:** Aceptado  
**Contexto:** Vehículos, Speakers, Venues tienen atributos distintos pero operaciones idénticas.  
**Decisión:** entity_types + entity_field_definitions + entity_instances con columna `attributes JSONB`. No EAV completo.  
**Límite:** Solo para entidades del catálogo extendido. Las entidades core (proyectos, órdenes, usuarios) permanecen relacionales.  
**Consecuencia:** Búsquedas sobre atributos dinámicos son más lentas. Mitigado con índices GIN.

---

### ADR-008: Crear dominio financiero (financial-service)

**Estado:** Aceptado — implementación en Fase 2  
**Contexto:** No existe dominio financiero. Los centros de costo están en project-service. La facturación no está modelada.  
**Decisión:** financial-service (NestJS) gestiona Budget, ActualCost, Invoice, Payment. Comienza como servicio liviano y crece con la necesidad.  
**Alternativa descartada:** Incluir finanzas en project-service. Descartada porque las responsabilidades financieras (reconciliación, facturación, cobros) son un dominio distinto con su propio ciclo de vida.

---

### ADR-010: creative-service y manufacturing-service — arquitectura definitiva

**Estado:** Aceptado

**Decisión:**
- **creative-service** → Servicio independiente. Bounded context propio.
- **Manufacturing** → Módulo especializado dentro de operations-service.

**Justificación para creative-service independiente:**
El dominio Creative gestiona entidades que no existen en ningún otro bounded context: Creative Assets (entregables de diseño), Design Versions (historial de iteraciones), Approval Requests (revisión formal por el cliente), Blueprints, Renders y Design Reviews. Estas entidades tienen su propio ciclo de vida, sus propias transiciones de estado y su propia lógica de negocio. No son Work Orders con un tipo diferente; son un dominio diferente con un modelo diferente.

**Justificación para Manufacturing como módulo:**
Manufacturing (fabricación de elementos para un evento) es una forma especializada de ejecutar una Work Order. Tiene los mismos actores (departamento, recursos, fechas), las mismas operaciones (crear, confirmar, ejecutar, completar) y el mismo modelo de datos que una Order operacional. La diferencia está en los pasos internos de producción, no en el dominio. operations-service puede modelar esta especialización internamente sin necesidad de un servicio independiente.

**Responsabilidades definitivas:**

`creative-service`:
- Creative Assets, Design Versions, Approvals, Blueprints, CAD, Renders, Design Reviews

`operations-service` (incluye módulo Manufacturing):
- Work Orders, Assignments, Planning, Execution, Scheduling, Field Operations
- Módulo Manufacturing: producción de elementos físicos como tipo especializado de Work Order

---

### ADR-009: marketplace-service — Inicio como módulo vs servicio independiente

**Estado:** Pendiente de decisión  
**Contexto:** Marketplace (contratación de proveedores externos) es un dominio claro, pero a la escala actual puede ser prematuro crear un servicio adicional.  
**Opción A:** Servicio independiente desde el inicio. Limpio arquitectónicamente. Mayor overhead operacional.  
**Opción B:** Módulo dentro de operations-service con separación de responsabilidades clara, y extracción cuando la complejidad del proceso de contratación lo justifique.  
**Recomendación:** Opción B inicialmente. El dominio está definido, la implementación puede comenzar acoplada y extraerse cuando el volumen o la complejidad lo justifiquen.  
**Decisión final:** Pendiente.

---

### ADR-011: Autorización dentro de identity-service — extracción futura como authorization-service

**Estado:** Documentado — implementación diferida  
**Contexto:** `identity-service` contiene dos bounded contexts internos: autenticación (quién eres) y autorización (qué puedes hacer). Conviven en el mismo servicio por simplicidad operacional en Phase 1. Los paquetes `authentication/` y `authorization/` están aislados desde el primer commit.  
**Opción A — Separar desde el inicio:** Dos servicios independientes. Limpio arquitectónicamente. Overhead operacional doble para Phase 1.  
**Opción B — Coexistencia con separación interna de paquetes (adoptada):** Un solo servicio, dos paquetes claramente delimitados. La extracción futura es un corte limpio: copiar el paquete `authorization/` a un nuevo servicio y cambiar los adapters.  
**Criterios de activación para extraer authorization-service:**
- Más de 3 tipos de scope distintos en producción (ABAC, feature flags, multiempresa)
- El módulo `authorization/` supera el 40% del código de `identity-service`
- Demanda de delegaciones, permisos temporales o integración con proveedor de identidad externo  
**Decisión final:** Opción B. Se documenta aquí como camino de evolución explícito.

---

### ADR-012: API Versioning — URI path versioning

**Estado:** Aprobado  
**Contexto:** Un ERP con integraciones externas (Power BI, apps móviles, marketplace, clientes externos) no puede romperse ante cambios de contrato. Necesitamos una estrategia de versionado desde el primer endpoint público.  
**Decisión:** URI path versioning.

**Reglas:**

| Tipo de endpoint | Prefijo | Versionado | Ejemplo |
|---|---|---|---|
| Público (Gateway expone) | `/api/v{n}/` | Sí | `/api/v1/projects` |
| Interno (service-to-service) | `/internal/` | No | `/internal/users/{id}/authorization` |

```
/api/v1/auth/login
/api/v1/users
/api/v1/projects
/api/v1/projects/{id}/status

-- Versión futura sin romper la v1:
/api/v2/projects
```

**Cambios que requieren nueva versión (breaking):**
- Eliminar o renombrar un campo de respuesta
- Cambiar el tipo de un campo existente
- Eliminar un endpoint
- Cambiar el significado semántico de un campo

**Cambios que no requieren nueva versión (non-breaking):**
- Agregar nuevos campos opcionales a la respuesta
- Agregar nuevos endpoints
- Agregar nuevos parámetros opcionales a una request

**Política de deprecación:**
- Mínimo 2 versiones soportadas simultáneamente
- Período de deprecación mínimo: 6 meses con header `Deprecation: true` en las respuestas
- El Gateway rutea por prefijo de versión; agregar v2 no afecta rutas de v1

**Decisión final:** Aprobado. Todo endpoint público lleva `/api/v{n}/` desde el primer servicio implementado.

---

### ADR-013: Estructura del repositorio Backend

**Estado:** Aprobado  
**Fecha:** 2026-08-04  
**Contexto:** El repositorio creció de forma orgánica durante la transición V1 → V2. Sin una estructura formal definida, cada servicio nuevo podría ubicarse en lugares distintos, duplicar configuración Maven, o confundirse con el código legacy. Se necesita una definición canónica que nunca vuelva a discutirse.

**Decisión:**

```
Backend/                          ← raíz del repositorio git
│
├── pom.xml                       ← Parent Maven (quantum-platform, packaging=pom)
│                                    Hereda: spring-boot-starter-parent
│                                    Gestiona: versiones de todas las dependencias
│                                    Módulos: shared/*, services/*
│
├── shared/
│   └── quantum-shared/           ← JAR de contratos compartidos (sin lógica de negocio)
│       └── pom.xml               ← hereda del parent
│
├── services/                     ← Un directorio por microservicio V2
│   ├── identity-service/         ← Fase 1 ✅
│   ├── project-service/          ← Fase 2 ✅
│   ├── crm-service/              ← Fase 3 (próximo)
│   └── ...
│       └── pom.xml               ← hereda del parent; sin versiones explícitas
│
├── infra/                        ← Infraestructura compartida de la plataforma
│   ├── docker-compose.yml        ← entorno de desarrollo
│   ├── docker-compose.prod.yml   ← overlay de producción
│   ├── .env.example              ← plantilla oficial de variables
│   ├── postgres/                 ← init-databases.sql, init-grants.sh
│   ├── prometheus/               ← prometheus.yml
│   └── secrets/                  ← gitignored: PEM, google-sa.json
│
├── legacy/                       ← CONGELADO — solo referencia histórica
│   ├── README.md                 ← define reglas de congelamiento
│   ├── auth-service/
│   ├── core-inventory/
│   └── ...
│
├── scripts/                      ← Herramientas de desarrollo y generación
│   └── generate-permissions.sh   ← (a crear en sprint de Authorization)
│
├── permissions.yaml              ← Catálogo oficial de permisos de la plataforma
└── .github/workflows/deploy.yml  ← CI/CD de la plataforma V2
```

**Reglas vinculantes:**

1. **Todo servicio V2 vive en `services/{nombre-servicio}/`** — nunca en raíz ni en `shared/`.
2. **Todo `pom.xml` de servicio hereda del parent** — nunca de `spring-boot-starter-parent` directamente.
3. **Las versiones de dependencias se declaran exclusivamente en `Backend/pom.xml`** — los hijos solo declaran `groupId` y `artifactId`.
4. **`infra/` es la única fuente de verdad de infraestructura** — ningún servicio crea su propio `docker-compose.yml`.
5. **`infra/secrets/` es gitignored** — ningún servicio genera sus propias claves; todas se montan desde `infra/secrets/`.
6. **`legacy/` es de solo lectura** — no hay nuevos commits con código en esa carpeta.
7. **`shared/quantum-shared` permanece mínimo** — solo contratos (DomainEventEnvelope, ProblemDetailResponse, constantes de correlación). Sin lógica de negocio, sin Spring, sin JPA.

**Añadir un nuevo servicio — checklist:**

```
□ Crear  services/{nombre}/                  con hexagonal arch (domain/application/infrastructure/shared)
□ Crear  services/{nombre}/pom.xml           heredando de quantum-platform
□ Crear  services/{nombre}/Dockerfile        con build context Backend/
□ Agregar módulo en Backend/pom.xml          (<module>services/{nombre}</module>)
□ Agregar bloque en infra/docker-compose.yml
□ Agregar bloque en infra/docker-compose.prod.yml
□ Agregar SVC_{NOMBRE}_PASSWORD en infra/.env.example
□ Agregar scrape job en infra/prometheus/prometheus.yml
□ Agregar secret SVC_{NOMBRE}_PASSWORD en GitHub → Settings → Secrets
□ Agregar entrada en .github/workflows/deploy.yml build matrix
□ Crear   services/{nombre}/.gitignore       (target/, secrets/, *.pem, .env*)
□ Crear   services/{nombre}/.dockerignore
```

**Alternativas descartadas:**

- *Mono-repo con Gradle multi-project*: descartado porque los servicios existentes usan Maven y Spring Boot starter parent ya provee los defaults necesarios.
- *Un repositorio git por servicio*: descartado por overhead de CI/CD, sincronización de versiones y friction de desarrollo durante la fase de construcción inicial.
- *`shared/` como repositorio Maven publicado*: descartado (YAGNI) — se revisará si la plataforma escala a equipos completamente independientes.

**Consecuencias:**

- Agregar un servicio es mecánico y predecible.
- Un único `mvn install` desde `Backend/` compila toda la plataforma en orden correcto.
- Las actualizaciones de Spring Boot, Jackson, Flyway, etc. se aplican en un solo commit al parent POM.

### ADR-014: Capability Discovery — Contratos verificables en tiempo de carga

**Estado:** Diferido — no implementar hasta que se cumplan los triggers.  
**Fecha de registro:** 2026-08-04  
**Relación:** Evolución natural de P-ENG-002 (Catálogo de Capacidades) y P-ENG-003 (Business Contracts).

**Contexto:**

Los principios P-ENG-001/002/003 definen una arquitectura de Engine → Contract → Module. Hoy los contratos son declarativos y documentados; la validación es responsabilidad del desarrollador en tiempo de diseño. Eso es suficiente mientras el número de módulos es pequeño y los contratos son estables.

A medida que la plataforma crezca, aparecerán dos problemas:

1. **Capacidades inexistentes**: un módulo podría intentar usar una capacidad que el Engine no soporta, sin que el sistema lo detecte automáticamente hasta tiempo de ejecución.
2. **Incompatibilidad de versiones**: un módulo configurado contra `Inventory Contract v1` podría cargarse contra un Engine que ya evolucionó a `Contract v2`, con comportamientos silenciosamente incorrectos.

**Decisión diferida:**

Cuando se cumplan los triggers (ver abajo), implementar **Capability Discovery**: el propio Engine declara formalmente las capacidades que soporta, y el sistema valida automáticamente que cada módulo solo use capacidades existentes y versiones compatibles.

**Diseño conceptual:**

```yaml
# Engine — declara sus capacidades (el Engine es la fuente de verdad)
engine: INVENTORY
contract_version: "1"
capabilities:
  - ASSET_REGISTRY
  - TRANSFER
  - RESERVATION
  - INSPECTION
  - MAINTENANCE
  - QR_BARCODE
  - RFID
  - LIFECYCLE_TRACKING
  - KITS
  - BATCH_OPERATIONS
  - AUDIT_TRAIL

# Módulo — declara qué usa (el sistema valida contra el Engine)
engine: INVENTORY
contract_version: "1"
uses:
  - ASSET_REGISTRY
  - TRANSFER
  - QR_BARCODE
```

Validaciones automáticas que habilitaría:
- `ASSET_REGISTRY` no existe en este Engine → error en carga de configuración.
- Dependencia implícita: `RESERVATION` requiere `ASSET_REGISTRY` → error si el módulo declara `RESERVATION` sin `ASSET_REGISTRY`.
- Módulo usa `contract_version: "1"` pero el Engine está en `contract_version: "2"` → advertencia o error configurable.

**Triggers para implementar:**

| Trigger | Umbral orientativo |
|---------|-------------------|
| Número de Business Modules por Engine | ≥ 5 módulos en un mismo Engine |
| Versiones de contrato activas simultáneamente | ≥ 2 versiones en producción |
| Incidente por capacidad inexistente o incompatibilidad | Primer incidente en producción |

**Por qué no ahora (YAGNI):**

Con 3 módulos por Engine y contratos estables, la validación manual en tiempo de diseño tiene coste cero y la discovery añade complejidad de infraestructura sin beneficio proporcional. El modelo documentado en P-ENG-002 y P-ENG-003 es suficiente durante la fase de construcción inicial.

**Alternativas que no requieren implementar esto todavía:**

- Tests de contrato (Pact) — verifican compatibilidad sin infraestructura de discovery.
- Validación en CI — un script compara la configuración del módulo contra una lista de capacidades declaradas en el repositorio.

### ADR-015: API Gateway — Spring Cloud Gateway

**Estado:** Aprobado  
**Fecha:** 2026-08-04  
**Contexto:** Toda petición a la plataforma Quantum debe pasar por un punto de entrada único antes de llegar a los servicios. El Gateway no será un proxy simple: concentra validación de JWT, propagación de contexto de seguridad, correlación de trazas, rate limiting y auditoría de acceso. Se necesita una tecnología que permita implementar esa lógica con código, no solo con configuración estática.

**Decisión:** Spring Cloud Gateway.

**Razones:**

| Criterio | Spring Cloud Gateway | Nginx/Kong/Traefik |
|----------|---------------------|-------------------|
| Plataforma | Java 21 + Spring Boot — sin cambio de stack | Servicio adicional fuera del ecosistema |
| Lógica en filtros | Código Java con acceso a Spring context (JWTs, Redis, MDC) | Lua (Kong) o configuración YAML (Traefik) — limitados |
| JWT verification con JWKS | `ReactiveJwtDecoder` nativo, JWKS con caché automática | Requiere plugin o módulo externo |
| Correlation ID | `ServerWebExchange` filter con MDC propagation | Limitado o requiere plugin |
| Rate limiting | `RequestRateLimiter` con Redis — configurable por ruta | Soportado pero fuera del modelo de datos de Spring |
| Observabilidad | Micrometer + Zipkin nativos | Requiere configuración adicional |
| Routing inteligente | `RouteLocator` programático | Solo YAML/config estática |
| Consistencia operacional | Un solo runtime, un solo health endpoint | Operación de un nuevo proceso |

**Responsabilidades del Gateway en Quantum:**

```
Petición entrante
      ↓
[1] CORS filter              — orígenes permitidos (FRONTEND_URL)
[2] Correlation ID filter    — genera o propaga X-Correlation-Id
[3] JWT verification         — valida firma con JWKS cacheado de identity-service
[4] Session context filter   — extrae sub + sid, escribe X-User-Id, X-Session-Id
[5] Rate limiting            — por IP y por usuario autenticado (Redis)
[6] Request logging          — method, path, userId, correlationId, latency
[7] Routing                  — dispatch al servicio backend
      ↓
Servicio backend  (recibe headers propagados, no valida JWT de nuevo)
```

**Headers propagados a todos los servicios:**

| Header | Valor | Origen |
|--------|-------|--------|
| `X-User-Id` | UUID del usuario | Extraído del JWT `sub` |
| `X-Session-Id` | UUID de la sesión | Extraído del JWT `sid` |
| `X-Correlation-Id` | UUID de la petición | Generado o propagado por el Gateway |
| `X-Forwarded-For` | IP real del cliente | Añadido por el Gateway |

**Lo que el Gateway nunca hace:**

- No evalúa permisos (eso es responsabilidad de cada servicio vía identity-service).
- No conoce la lógica de negocio de ningún Engine.
- No modifica el body de las peticiones.

**Estructura del módulo:**

```
services/
  gateway-service/
    pom.xml                 ← hereda de quantum-platform
    Dockerfile
    src/main/java/
      global/brandex/quantum/gateway/
        GatewayApplication.java
        filter/
          CorrelationIdFilter.java
          JwtContextFilter.java
          RequestLoggingFilter.java
        config/
          RouteConfig.java
          SecurityConfig.java
          RateLimitConfig.java
        GatewayProperties.java
    src/main/resources/
      application.yml
      application-development.yml
```

**Consecuencias:**

- Ningún servicio backend necesita configurar CORS, rate limiting ni logging de acceso — el Gateway lo centraliza.
- Todos los servicios confían en los headers propagados; nunca revalidan el JWT.
- El Gateway es el único componente que conoce las URLs externas de los servicios. Los servicios se descubren por hostname interno (Docker network).

**Alternativas descartadas:**

- *Nginx*: no programable en Java; implementar JWT verification requiere módulos externos; rompe la uniformidad del stack.
- *Kong*: excelente producto pero introduce un servicio de base de datos propio (PostgreSQL o Cassandra) y un plano de control separado — overhead operacional desproporcionado para la fase actual.
- *Traefik*: orientado a configuración automática por etiquetas Docker; no apropiado para filtros personalizados de negocio.

---

### ADR-016: RuntimeContext — Diseño del Objeto Central

**Fecha:** 2026-08-04  
**Estado:** En decisión (diseño pendiente en Sprint 6)  
**Contexto:** P-ENG-005 define el Business Runtime como la pieza que convierte declaraciones en comportamiento. El `RuntimeContext` es el objeto que el Runtime produce como resultado de procesar un Blueprint completo. Se ha dicho que es "el objeto más importante de toda la plataforma Quantum". Ese nivel de importancia exige un ADR propio con respuesta explícita a cada pregunta que afecta su ciclo de vida.

**Preguntas de diseño que Sprint 6 debe responder:**

| # | Pregunta | Implicación si se decide mal |
|---|----------|------------------------------|
| 1 | ¿Es completamente inmutable? | Si es mutable, la predictibilidad de la plataforma cae — el mismo Blueprint puede producir comportamiento diferente en dos instancias |
| 2 | ¿Puede recompilarse en caliente? | Si no puede, un cambio de Blueprint requiere reinicio del servicio — impacto en disponibilidad |
| 3 | ¿Cómo se versiona? | Un módulo apunta a `INVENTORY_ONLY@v1` — ¿el RuntimeContext se vincula a esa versión explícita? |
| 4 | ¿Se serializa? | Si el RuntimeContext necesita cruzar una red o persistirse, debe ser serializable — eso afecta todos los tipos que contiene |
| 5 | ¿Se distribuye? | En un entorno con múltiples instancias del Runtime, ¿cada instancia compila su propio RuntimeContext o existe uno compartido? |
| 6 | ¿Puede cachearse? | Si el mismo Blueprint produce el mismo RuntimeContext, el caché es trivial — pero requiere definir cuándo el caché es inválido |
| 7 | ¿Quién lo construye? | ¿El Runtime lo construye una sola vez al arrancar? ¿Lo construye por petición? ¿Existe un builder explícito? |
| 8 | ¿Quién lo invalida? | Si un Blueprint se depreca, todos los RuntimeContext compilados desde esa versión deben invalidarse — ¿cómo? |

**Analogía arquitectónica:** el `RuntimeContext` es al Business Runtime lo que el `ApplicationContext` de Spring es al framework: el objeto central que orquesta todo lo demás. Diseñarlo como un detalle de implementación sería un error que se paga durante años.

**Alternativas de inmutabilidad:**

| Opción | Descripción | Consecuencia |
|--------|-------------|--------------|
| **Inmutable total** | Una vez compilado, no puede modificarse. Un cambio de Blueprint compila un nuevo RuntimeContext. | Predictibilidad máxima. Recarga implica reemplazar el objeto completo. |
| **Inmutable por campo** | Cada campo del RuntimeContext es inmutable, pero puede construirse un nuevo contexto reemplazando campos específicos. | Más flexible para recargas parciales, más complejo de implementar. |
| **Mutable gestionado** | El RuntimeContext puede modificarse pero solo a través de operaciones del Runtime, nunca directamente. | Riesgo de state inconsistente si dos hilos modifican simultáneamente. |

**Decisión recomendada:** inmutable total con soporte de recarga atómica. Sprint 6 confirma o revisa.

**Criterio de aceptación de Sprint 6 para este ADR:** un documento de diseño que responda las ocho preguntas con decisiones concretas, no opciones. El formato importa: las decisiones, no los análisis.

---

### ADR-017: Blueprint Storage — ¿Dónde viven los Blueprints?

**Fecha:** 2026-08-04  
**Estado:** En decisión (debe resolverse antes de implementar el Blueprint Registry en Sprint 6)  
**Contexto:** el Blueprint Registry es el componente que el Runtime consulta para descubrir y cargar Blueprints. Su diseño depende de dónde se almacenen los archivos `.yml` de Blueprint. Esta decisión condiciona el ciclo de despliegue, la auditoría, el versionado y la operación del Runtime.

**Opciones:**

| Opción | Descripción | Ventajas | Riesgos |
|--------|-------------|----------|---------|
| **A — Git como fuente de verdad** | Los `.yml` de Blueprint viven en el repositorio. El Runtime los carga desde el classpath o desde un directorio montado. | Auditoría completa por git history. Versionado gratuito. Revisión via PR. | El ciclo de despliegue de un Blueprint es igual al de un deploy. Requiere reinicio o recarga para activar un Blueprint nuevo. |
| **B — Base de datos** | Los Blueprints persisten en una tabla del sistema. El Runtime los carga por consulta. | Activación sin deploy. Rollback por update de fila. Multi-tenant por diseño. | Los Blueprints salen del control de versiones. Auditoría requiere infraestructura adicional. Riesgo de drift entre lo que hay en BD y lo que hay en Git. |
| **C — Registry central (servicio HTTP)** | Existe un microservicio `blueprint-registry` que expone los Blueprints por API. | Centralización. Desacoplamiento del filesystem. Soporte multi-instancia nativo. | Añade un servicio con su propio ciclo de vida. El Runtime tiene dependencia de red en tiempo de arranque. Complejidad operacional. |
| **D — Híbrido: Git + Registry sincronizado** | Git es la fuente de verdad. Un proceso de CI/CD sincroniza los Blueprints al Registry (BD o caché). El Runtime consulta el Registry, no Git directamente. | Auditoría completa por Git. Activación casi inmediata. Sin dependencia de red en caliente. | Requiere proceso de sincronización. Riesgo de desincronización si el proceso falla. |

**Implicaciones cruzadas:**

- La opción elegida afecta P-ENG-005 (cómo el Runtime descubre Blueprints).
- La opción elegida afecta la política de inmutabilidad de BUSINESS_BLUEPRINT_SPEC.md §7 (si los Blueprints están en Git, la inmutabilidad es trivialmente auditable).
- La opción elegida afecta el criterio de aceptación de Sprint 7 (el Runtime MVP debe poder cargar el Blueprint de KeepMe — ¿desde dónde?).

**Recomendación inicial:** **Opción A** para Sprint 6 y 7 (Git + classpath — mínimo viable, auditoría gratuita). **Opción D** como evolución natural cuando existan múltiples instancias del Runtime o se necesite activación sin deploy. Sprint 6 confirma o revisa.

**Decisión a formalizar en Sprint 6:** la opción elegida, el mecanismo exacto de carga, y el criterio de invalidación del caché de RuntimeContext cuando un Blueprint cambia.

---

## 20. Hoja de Ruta de Migración

### Estado oficial de la arquitectura — 2026-08-03

**Backend V1 → Estado: LEGACY**

El Backend V1 (`auth-service`, `core-inventory`, `logistics-optimizer`, `currency`, `notifications`, `gateway`) pasa oficialmente a estado LEGACY a partir de esta fecha.

| Regla | Descripción |
|---|---|
| Sin desarrollo nuevo | No se implementan funcionalidades ni mejoras sobre servicios V1 |
| Solo correcciones críticas | Únicamente bugs que afecten la operación en producción |
| Referencia funcional permitida | El código V1 puede consultarse para entender reglas de negocio existentes |
| Sin copiar técnicamente | Arquitectura, estructura de paquetes, configuraciones e implementaciones V1 no deben replicarse en V2 |

**Backend V2 → Estado: ACTIVO**

Todo desarrollo nuevo ocurre exclusivamente sobre `Backend/services/`. Los servicios V2 siguen la Architecture Blueprint v2.x, los Platform Standards v1.x y los ADRs vigentes.

> V1 no fue un error. Fue el sistema que permitió entender el negocio antes de modelarlo formalmente. V2 existe porque V1 cumplió su propósito.

---

### Roadmap activo — Basado en P-ENG (2026-08-04)

> La arquitectura de Business Engines (P-ENG-001/002/003) redefine el roadmap. Ya no se habla de "construir KeepMe" o "construir el CRM". Se habla de construir **Engines**, y después registrar módulos como configuraciones. Eso cambia la pregunta que guía cada sprint: no ¿qué servicio hacemos?, sino ¿a qué Engine pertenece este requerimiento?

**Principio de secuencia:** ninguna fase comienza sin que la anterior esté estable y validada en su totalidad.

---

### Las Dos Etapas de Quantum

El roadmap completo se divide en dos bloques conceptualmente distintos. Cruzar la frontera entre ambos marca el momento en que Quantum deja de ser una plataforma en construcción y se convierte en una plataforma en uso.

```
┌─────────────────────────────────────────────────────────────┐
│  ETAPA A — Foundation Platform                              │
│                                                             │
│  Piensas en Quantum.                                        │
│  No en KeepMe. No en Celebrate.                             │
│                                                             │
│  Construyes la plataforma capaz de ejecutar cualquier       │
│  Blueprint antes de que exista un solo módulo real.         │
│  Y demuestras que sus principios son verificables.          │
│                                                             │
│  Fase A  Sprint 3: API Gateway                              │
│          Sprint 4: Authorization Platform                   │
│  Fase B  Sprint 5: Business Blueprint Specification         │
│  Fase C  Sprint 6: Runtime Technical Design                 │
│          Sprint 7: Runtime MVP                              │
│  Fase D  Sprint 8: Architecture Validation Suite            │
└─────────────────────────────────────────────────────────────┘
                            │
                            │  La plataforma existe.
                            │  La arquitectura está verificada.
                            │  Ahora se puede ensamblar.
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  ETAPA B — Business Assembly                                │
│                                                             │
│  Piensas en módulos.                                        │
│  Porque ya no los programas: los ensamblas.                 │
│                                                             │
│  Fase E  Sprint 9:   Inventory Engine                       │
│          Sprint 10:  KeepMe                                 │
│          Sprint 11+: Celebrate, SWAG, CRM, Realización...   │
└─────────────────────────────────────────────────────────────┘
```

---

### Fase A — Infrastructure Platform

**Objetivo:** que toda petición de Quantum viaje por la misma autopista antes de que exista un solo Engine de negocio.

| Sprint | Nombre | Entregable |
|--------|--------|-----------|
| **Sprint 3** | API Gateway | Spring Cloud Gateway con JWT verification, JWKS cache, correlation IDs, rate limiting, logging, routing, CORS, compresión y session filter |
| **Sprint 4** | Authorization Platform | Módulo de autorización en identity-service: roles, permissions, resources, user_roles, service_identities, Redis cache, `/internal/users/{id}/authorization`, Service JWTs |

**Criterio de salida:** cualquier servicio nuevo que se despliegue ya nace protegido sin configuración adicional de seguridad.

---

### Fase B — Business Language

**Objetivo:** antes de escribir una línea de código de negocio, definir formalmente el lenguaje con el que los negocios se ensamblan.

| Sprint | Nombre | Entregable |
|--------|--------|-----------|
| **Sprint 5** | Business Blueprint Specification | Ver objetivos detallados abajo |

**Sprint 5 — Objetivos:**

Sprint 5 no produce código de negocio. Produce el lenguaje y el mapa. Cuando existan ambos, el crecimiento de la plataforma cambia de naturaleza: la mayor parte de los nuevos módulos serán declaraciones YAML, no implementaciones Java.

1. **Definir el schema canónico de `business-blueprint.yml`** — el lenguaje oficial de declaración de módulos: `module`, `metadata`, `engines`, `contracts`, `capabilities`, `workflows`, `events`, `permissions`, `configuration`, `ui`. *(Completado: `BUSINESS_BLUEPRINT_SPEC.md`)*

2. **Especificar composición multi-Engine** — cómo un Blueprint puede referenciar Contracts de múltiples Engines simultáneamente sin que ningún Engine conozca a los demás. *(Completado: P-ENG-004 + BUSINESS_BLUEPRINT_SPEC.md §3.3)*

3. **Definir reglas de validación** — compatibilidad de Contracts, dependencias entre Capabilities (grafo de `requires`), versiones, eventos producibles vs. consumibles. *(Completado: BUSINESS_BLUEPRINT_SPEC.md §5)*

4. **Crear tres Blueprints reales** para validar que el modelo soporta composiciones complejas sin cambios en los Engines:

   | Blueprint | Engines compuestos | Propósito de validación |
   |-----------|-------------------|------------------------|
   | **KeepMe** | Inventory | Validar el caso simple: un Engine, múltiples Capabilities con grafo de dependencias |
   | **Celebrate** | Inventory + CRM | Validar composición bi-Engine: reserva de activos disparada por deal CRM |
   | **SWAG** | Inventory + Creative + Manufacturing | Validar composición tri-Engine: producción de mercancía de marca (diseño → manufactura → inventario) |

5. **Actualizar `BUSINESS_ENGINES_CATALOG.md`** — Capabilities formalmente tipadas para cada Engine, Business Contracts versionados, Blueprints registrados. *(En progreso)*

> Cuando Sprint 5 esté completo, agregar un módulo nuevo será como declarar su comportamiento. No será como escribir software.

---

### Fase C — Business Runtime

**Objetivo:** diseñar e implementar el sistema operativo de Quantum — la pieza que convierte declaraciones YAML en pipelines ejecutables. La plataforma no puede ensamblar nada sin él.

| Sprint | Nombre | Entregable |
|--------|--------|-----------|
| **Sprint 6** | Runtime Technical Design | Ver preguntas de diseño abajo |
| **Sprint 7** | Runtime MVP | Ver criterio de aceptación abajo |

---

**Sprint 6 — Runtime Technical Design**

Sprint 6 no produce código. Produce el diseño técnico completo del Platform Runtime: los ocho componentes, sus interfaces, sus responsabilidades y la secuencia exacta de `Platform.start()`.

**El entregable de Sprint 6 es `PLATFORM_RUNTIME_DESIGN.md`.**

Los ocho componentes que ese documento especifica:

| Componente | Responsabilidad |
|------------|----------------|
| **Module Registry** | Sabe qué módulos están activos: `register()`, `find()`, `list()` |
| **Engine Registry** | Sabe qué Engines están disponibles y cómo invocarlos |
| **Contract Registry** | Sabe qué contratos existen y qué versión expone cada Engine |
| **Capability Registry** | Almacena `CapabilityDescriptor` con dependencias, permisos y eventos |
| **Blueprint Compiler** | Lee `.yml` → valida 7 capas → produce `RuntimeContext` inmutable |
| **Runtime Loader** | Recibe `RuntimeContext` → orquesta la activación de Engines → registra el módulo |
| **Module Installer** | Publica rutas, navegación, permisos, menus, workflows y eventos automáticamente |
| **Engine Dispatcher** | Cuando llega `POST /keepme/assets` → sabe que es `Inventory → ASSET_REGISTRY` sin que Inventory sepa nada de KeepMe |

**La pregunta que Sprint 6 responde por completo:**

Si al final del sprint alguien escribe:

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

El equipo debe poder señalar en `PLATFORM_RUNTIME_DESIGN.md` exactamente qué componente procesa cada línea, en qué orden, y qué error produce si algo está mal.

**Criterio de salida Sprint 6:** `PLATFORM_RUNTIME_DESIGN.md` completo. El equipo puede comenzar Sprint 7 sin resolver una sola duda de diseño.

---

**Sprint 7 — Runtime MVP ✅ IMPLEMENTADO**

Sprint 7 implementa los 8 componentes del Platform Runtime como un microservicio Spring Boot (`platform-runtime`, puerto 8090). El descubrimiento de Engines se basa en HTTP: cada Engine expone `GET /engine/manifest`; el Runtime llama esos endpoints en `ApplicationReadyEvent` usando URLs configuradas en `application.yml`.

**Nota sobre implementación:** el diseño original describía un `Platform.start()` en-JVM sin HTTP. La implementación es distributed-first: cada Engine es un proceso independiente con su propio endpoint de manifesto. Esto hace la arquitectura más robusta y fiel al modelo de microservicios.

**Estado:** `platform-runtime` completamente implementado e integrado con `inventory-service`. Ver §11 para el catálogo completo de componentes.

**Criterio de aceptación cumplido:**

**Componentes que Sprint 7 implementa (MVP):**

| Componente | Alcance en Sprint 7 |
|------------|-------------------|
| Capability Registry | Registra las Capabilities de Inventory Engine en memoria |
| Contract Registry | Registra el Contract `inventory-v1` |
| Engine Registry | Registra el Inventory Engine con su handler |
| Blueprint Compiler | Ejecuta los 7 pasos de validación sobre `keepme.yml` |
| Runtime Loader | Carga el `RuntimeContext`, llama `Engine.init(BusinessContext)` |
| Module Registry | Almacena el `ModuleDescriptor` de KeepMe |
| Module Installer | Publica rutas, nav, permisos en log (no en HTTP todavía) |
| Engine Dispatcher | Resuelve `(keepme, ASSET_REGISTRY)` → Inventory Engine |

**El output del criterio de aceptación:**

Dado `keepme.yml` correctamente declarado, `Platform.start()` produce exactamente:

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

Y dado un `keepme.yml` que declara `MAINTENANCE` (Capability no activa para KeepMe):

```
Resolving Capabilities...
  ✓ Asset Registry
  ✗ MAINTENANCE — CAPABILITY_NOT_IN_CONTRACT: inventory-v1 does not expose MAINTENANCE
  
Compilation failed. Module not registered.
```

**Log real de startup del Platform Runtime implementado:**

```
=== Platform Runtime Bootstrap ===
Discovering 1 configured engine(s)...
[RuntimeLoader] Discovering engine 'inventory' at http://localhost:8082
[RuntimeLoader] Engine 'inventory' v1.0.0 registered — 12 capabilities, 1 contracts
[RuntimeLoader] ✓ Engine 'inventory' dependency graph validated — Engine is READY
=================================
Platform Runtime ready. 1/1 engine(s) READY.
=================================
```

**Criterio de aceptación Sprint 7:** ✅ cumplido. La hipótesis "Los negocios no se programan: se ensamblan" tiene su primera demostración ejecutable. El siguiente paso (Sprint 10) es instalar el Blueprint de KeepMe vía `POST /runtime/modules` sin modificar una línea del Inventory Engine.

---

### Fase D — Architecture Validation

**Objetivo:** antes de construir el primer Engine de negocio, demostrar que los principios P-ENG son verificables automáticamente. Los principios sin pruebas automáticas son convenciones que se erosionan con el tiempo.

| Sprint | Nombre | Entregable |
|--------|--------|-----------|
| **Sprint 8** | Architecture Validation Suite | Ver checks detallados abajo |

**Sprint 8 — Architecture Validation Suite:**

Sprint 8 no produce código de negocio. Produce las pruebas que convierten los principios P-ENG y P-ARC en reglas verificables en cada commit. Cuando la suite existe, nadie puede romper la arquitectura accidentalmente — el pipeline de CI lo detecta antes del merge.

| Check | Principio que verifica | Herramienta sugerida |
|-------|----------------------|---------------------|
| ✓ Ningún Engine importa clases de otro Engine | P-DOM-001 + P-ARC-002 | ArchUnit (Java) |
| ✓ Ningún Engine recibe `ModuleName` en ningún constructor ni método público | P-ENG-001 | ArchUnit |
| ✓ Ninguna clase del Runtime importa clases de dominio de negocio | P-ARC-002 | ArchUnit |
| ✓ Todo Blueprint declarado es válido contra su Contract | P-ENG-004 | Test de carga + validator |
| ✓ Todas las dependencias del grafo de Capabilities pueden resolverse | P-ENG-002 | Test del Capability Graph |
| ✓ No existen dependencias circulares en el grafo de Capabilities | P-ENG-002 | Test del Capability Graph |
| ✓ Todo evento consumido por algún Blueprint es publicado por algún Engine | P-ENG-002 | Test del EventSchema |
| ✓ Todo `RuntimeContext` compilado es inmutable (no existen setters) | ADR-016 | ArchUnit |

**Métricas de arquitectura que Sprint 8 registra por primera vez:**

| Métrica | Propósito |
|---------|-----------|
| Número de Engines | Referencia de complejidad de plataforma |
| Número de Capabilities por Engine | Detectar Engines con demasiadas responsabilidades |
| Profundidad máxima del grafo de Capabilities | Detectar cadenas de dependencia excesivamente largas |
| Número de Blueprints registrados | Referencia del catálogo de módulos |
| Número medio de Engines por Blueprint | Detectar Blueprints de composición anormalmente compleja |
| Tiempo de compilación de un RuntimeContext | Baseline de rendimiento del Runtime |
| Tiempo de inicialización del Runtime completo | Baseline de rendimiento del arranque |

Estas métricas permiten responder dentro de dos años la pregunta "¿estamos complicando el sistema?" con datos, no con opiniones.

**Criterio de salida:** la suite corre en CI como parte del proceso de build. Un PR que viola cualquier check de la lista no puede mergearse. Un Engine que importa a otro Engine es bloqueado automáticamente.

---

### Fase E — Business Assembly

**Objetivo:** construir los Engines, no los módulos. Un módulo es una declaración; el Engine es el artefacto técnico. La plataforma existe, la arquitectura está verificada — ahora se ensambla.

| Sprint | Nombre | Entregable |
|--------|--------|-----------|
| **Sprint 9** | Inventory Engine | `inventory-service` completo — todas las Capabilities del catálogo definido en Sprint 5, integradas con el Runtime de Sprint 7 y validadas por la suite de Sprint 8 |
| **Sprint 10** | KeepMe | Primera declaración Blueprint en producción. No un nuevo servicio: un `business-blueprint.yml` interpretado por el Runtime |
| **Sprint 11+** | Siguientes Engines | CRM Engine → Creative Engine → Manufacturing Engine → Service Engine, en el orden que determine la prioridad de negocio |

**Nota sobre nomenclatura:** KeepMe, Celebrate y CustomX son nombres comerciales. Técnicamente no existen como servicios — son configuraciones del Inventory Engine. Esta distinción debe ser visible en el código: no hay un `keepme-service`, hay un `inventory-service` con configuración `module: KEEPME`.

**Nota sobre Business Assembly:** a partir de Sprint 10, agregar un módulo nuevo es declarar su comportamiento en un `business-blueprint.yml`. No es escribir un nuevo servicio. Si el Runtime existe, el Engine existe y la suite de Sprint 8 pasa, el módulo es YAML.

---

### Histórico pre-P-ENG (referencia)

Las fases 0–4 definidas antes de formalizar la arquitectura de Engines describían la migración V1 → V2 por extracción de servicios desde `core-inventory`. Esa narrativa queda como registro histórico pero **no orienta el desarrollo activo**. El roadmap vigente es el basado en P-ENG descrito arriba.

---

## 21. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Pérdida de datos de CRM durante migración desde localStorage | Alta | Alto | Script de exportación validado + ventana de migración comunicada con tiempo suficiente |
| Ruptura de API durante extracción de servicios | Media | Alto | Versioning de API + doble escritura temporal + período de transición con ambos servicios activos |
| El broker de mensajería (Redis Streams) no cumple con los requisitos de durabilidad | Media | Medio | Monitoreo de profundidad de cola + plan de migración a Kafka documentado |
| Complejidad operacional excede la capacidad actual del equipo | Media | Alto | Ejecutar fases secuencialmente, nunca en paralelo. No comenzar Fase 1 sin Fase 0 estable. |
| Degradación de rendimiento por llamadas cross-service | Media | Medio | Cache de Redis para consultas frecuentes. Evitar N+1 queries. |
| MinIO pierde datos en producción | Baja | Alto | Replication policy en MinIO + backup periódico a S3 |
| Deuda técnica acumulada durante la migración incremental | Alta | Medio | Definir criterios claros de "done" por fase. No agregar nuevas funcionalidades sobre código que está en proceso de migración. |
| El dominio financiero crece en complejidad más allá de lo previsto | Media | Medio | Definir explícitamente el alcance de financial-service antes de implementar (no es un ERP financiero completo) |

---

*Este documento es la referencia arquitectónica oficial del proyecto. Toda decisión de diseño tomada durante el desarrollo debe ser consistente con los principios, el modelo de dominio y las decisiones (ADRs) aquí registrados. Cualquier excepción requiere un nuevo ADR que justifique técnicamente el desvío.*

*Versión 3.0 — Quantum ERP — Brandex Global — 2026-08-03*
