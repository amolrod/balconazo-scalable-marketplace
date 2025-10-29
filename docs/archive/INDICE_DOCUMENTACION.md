# 📚 ÍNDICE DE DOCUMENTACIÓN - PROYECTO BALCONAZO

**Última actualización:** 28 de octubre de 2025, 14:30

---

## 🎯 GUÍAS DE INICIO RÁPIDO

### 1. **README.md** 
📄 Documentación principal del proyecto
- Descripción general del marketplace
- Stack tecnológico completo
- Arquitectura de 3 microservicios
- Quick Start para desarrolladores
- Endpoints por servicio

### 2. **QUICKSTART.md**
⚡ Guía rápida para levantar el sistema en <30 minutos
- Requisitos previos
- Instalación paso a paso
- Comandos copy-paste
- Verificación de servicios
- Flujo de prueba E2E

### 3. **SIGUIENTES_PASOS.md** 🆕
🚀 Próximos pasos para implementar API Gateway & Auth Service
- Orden de implementación detallado
- Checklist completo
- Estimación de tiempos
- Comandos listos para ejecutar
- Criterios de éxito

---

## 📊 ESTADO DEL PROYECTO

### 4. **ESTADO_ACTUAL.md**
📈 Estado actualizado del proyecto (85% completo)
- Progreso por microservicio
- Infraestructura Docker
- Tópicos Kafka configurados
- Pruebas E2E realizadas
- Health checks

### 5. **HOJA_DE_RUTA.md**
🗺️ Roadmap completo del proyecto
- Fase 1: Infraestructura ✅
- Fase 2: Microservicios Core ✅
- Fase 3: Search Microservice ✅
- Fase 4: API Gateway & Auth 🔄 (en curso)
- Fase 5: Frontend Angular ⏭️
- Fase 6: Despliegue AWS ⏭️
- Cronograma detallado

### 6. **RESUMEN_FINAL.md**
✅ Resumen de lo completado hasta hoy
- Servicios operativos
- Correcciones implementadas
- Scripts disponibles
- Cómo usar el sistema

---

## 🔧 DECISIONES ARQUITECTÓNICAS

### 7. **docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md** 🆕
📋 ADR (Architecture Decision Record) sobre API Gateway
- **Decisión:** Gateway SIN JPA/MySQL
- **Razón:** Evitar conflicto reactive vs bloqueante
- **Alternativa:** Auth Service separado con MySQL
- Comparación de performance
- Flujo de autenticación completo
- Consecuencias de la decisión

### 8. **documentacion.md**
📖 Especificación técnica original completa
- Stack tecnológico detallado
- DDL de bases de datos
- Tópicos y eventos de Kafka
- Saga de booking con Outbox
- Motor de pricing dinámico
- Docker Compose

---

## 🐛 CORRECCIONES Y MEJORAS

### 9. **CORRECCIONES_IMPLEMENTADAS.md**
🔧 Detalle técnico de todas las correcciones realizadas
- Validación de fechas futuras corregida
- Excepciones personalizadas implementadas
- Códigos HTTP apropiados (400, 409, 500)
- Mensajes de error con contexto
- Snippets de código antes/después

### 10. **DIAGNOSTICO_COMPLETO.md**
🔍 Análisis completo de problemas identificados
- Diagnóstico de errores HTTP 400
- Problemas de validación
- Configuraciones incorrectas
- Soluciones implementadas paso a paso
- Estado final del sistema

---

## 📜 SCRIPTS Y HERRAMIENTAS

### 11. **GUIA_SCRIPTS.md**
🛠️ Guía de scripts de inicio y gestión
- `start-all.sh` - Iniciar sistema completo
- `start-catalog.sh` - Catalog Service individual
- `start-booking.sh` - Booking Service individual
- `start-search.sh` - Search Service individual
- `test-e2e.sh` - Pruebas end-to-end
- Ubicación de logs

---

## 📚 DOCUMENTACIÓN COMPLEMENTARIA

### 12. **docs/CHANGELOG.md**
📝 Historial de cambios del proyecto
- Versiones y releases
- Features añadidas
- Bugs corregidos

### 13. **docs/PRICING_ALGORITHM.md**
💰 Algoritmo de pricing dinámico
- Factores de precio
- Fórmulas aplicadas
- Ejemplos de cálculo

### 14. **docs/WIREFRAMES.md**
🎨 Wireframes del frontend (pendiente)
- Mockups de páginas
- Flujos de usuario

---

## 🗑️ DOCUMENTOS ELIMINADOS (Obsoletos)

Los siguientes documentos fueron eliminados por estar desactualizados o duplicados:

- ❌ `BOOKING_SERVICE_COMPLETADO.md` - Info duplicada en ESTADO_ACTUAL.md
- ❌ `REDIS_COMPLETO.md` - Info incluida en documentacion.md
- ❌ `RESUMEN_EJECUTIVO.md` - Reemplazado por RESUMEN_FINAL.md
- ❌ `TESTING.md` - Info incluida en QUICKSTART.md y test-e2e.sh
- ❌ `docs/MVP_STATUS.md` - Info duplicada en ESTADO_ACTUAL.md
- ❌ `docs/AUTH_SIMPLIFIED.md` - Reemplazado por ADR_API_GATEWAY_SIN_PERSISTENCIA.md

---

## 🚀 FLUJO DE LECTURA RECOMENDADO

### Para Nuevos Desarrolladores:
1. **README.md** - Entender qué es Balconazo
2. **QUICKSTART.md** - Levantar el sistema
3. **test-e2e.sh** - Ejecutar prueba completa
4. **ESTADO_ACTUAL.md** - Ver estado del proyecto
5. **SIGUIENTES_PASOS.md** - Qué falta por hacer

### Para Arquitectura y Diseño:
1. **documentacion.md** - Especificación completa
2. **docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md** - Decisión sobre Gateway
3. **HOJA_DE_RUTA.md** - Plan completo
4. **docs/PRICING_ALGORITHM.md** - Motor de pricing

### Para Debugging:
1. **DIAGNOSTICO_COMPLETO.md** - Problemas identificados
2. **CORRECCIONES_IMPLEMENTADAS.md** - Soluciones aplicadas
3. **GUIA_SCRIPTS.md** - Cómo ver logs
4. **ESTADO_ACTUAL.md** - Verificar health checks

### Para Implementar API Gateway:
1. **docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md** - Entender la decisión
2. **SIGUIENTES_PASOS.md** - Guía paso a paso
3. **HOJA_DE_RUTA.md** - Fase 4 completa
4. **documentacion.md** - Referencia técnica

---

## 📂 ESTRUCTURA DE CARPETAS

```
/Users/angel/Desktop/BalconazoApp/
├── README.md                          # Principal
├── QUICKSTART.md                      # Inicio rápido
├── SIGUIENTES_PASOS.md               # Próximos pasos 🆕
├── ESTADO_ACTUAL.md                   # Estado actual
├── HOJA_DE_RUTA.md                    # Roadmap
├── RESUMEN_FINAL.md                   # Resumen de hoy
├── CORRECCIONES_IMPLEMENTADAS.md      # Correcciones técnicas
├── DIAGNOSTICO_COMPLETO.md            # Diagnóstico completo
├── GUIA_SCRIPTS.md                    # Guía de scripts
├── documentacion.md                   # Especificación original
├── INDICE_DOCUMENTACION.md            # Este archivo
│
├── docs/                              # Documentación complementaria
│   ├── ADR_API_GATEWAY_SIN_PERSISTENCIA.md  🆕
│   ├── CHANGELOG.md
│   ├── PRICING_ALGORITHM.md
│   └── WIREFRAMES.md
│
├── catalog_microservice/
├── booking_microservice/
├── search_microservice/
├── api-gateway/                       # Por crear
├── auth-service/                      # Por crear
└── eureka-server/                     # Por crear
```

---

## 🔍 BÚSQUEDA RÁPIDA

### ¿Cómo levanto el sistema?
→ **QUICKSTART.md** o `./start-all.sh`

### ¿Cuál es el estado actual?
→ **ESTADO_ACTUAL.md** o **RESUMEN_FINAL.md**

### ¿Qué falta por hacer?
→ **SIGUIENTES_PASOS.md** y **HOJA_DE_RUTA.md**

### ¿Por qué el Gateway no tiene MySQL?
→ **docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md**

### ¿Cómo arreglo un error HTTP 400?
→ **DIAGNOSTICO_COMPLETO.md** y **CORRECCIONES_IMPLEMENTADAS.md**

### ¿Dónde están los logs?
→ **GUIA_SCRIPTS.md** (sección de logs)

### ¿Cómo funciona el pricing?
→ **docs/PRICING_ALGORITHM.md**

### ¿Cuáles son los endpoints?
→ **README.md** (sección de endpoints) o **documentacion.md**

---

## ✅ DOCUMENTOS ACTIVOS (15)

1. README.md
2. QUICKSTART.md
3. SIGUIENTES_PASOS.md 🆕
4. ESTADO_ACTUAL.md
5. HOJA_DE_RUTA.md
6. RESUMEN_FINAL.md
7. CORRECCIONES_IMPLEMENTADAS.md
8. DIAGNOSTICO_COMPLETO.md
9. GUIA_SCRIPTS.md
10. documentacion.md
11. INDICE_DOCUMENTACION.md (este archivo)
12. docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md 🆕
13. docs/CHANGELOG.md
14. docs/PRICING_ALGORITHM.md
15. docs/WIREFRAMES.md

---

**Última revisión:** 28 de octubre de 2025, 14:30  
**Próxima actualización:** Al completar Fase 4 (API Gateway & Auth Service)

