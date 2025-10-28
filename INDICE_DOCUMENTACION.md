# 📚 ÍNDICE DE DOCUMENTACIÓN - BALCONAZO

## 📖 DOCUMENTOS PRINCIPALES (Lectura recomendada)

### 1. **README.md** ⭐ INICIO AQUÍ
Documentación principal del proyecto con Quick Start, arquitectura, endpoints API y troubleshooting.

**Cuándo leerlo:** Primera vez que accedes al proyecto

### 2. **ESTADO_ACTUAL.md** 
Estado detallado del proyecto al 28 de Octubre de 2025. Incluye qué está funcionando, infraestructura, health checks, y checklist de validación.

**Cuándo leerlo:** Para saber exactamente qué está implementado y funcionando

### 3. **HOJA_DE_RUTA.md**
Roadmap completo del proyecto dividido en 5 fases. Plan detallado de implementación del Search Microservice y fases futuras.

**Cuándo leerlo:** Para entender la visión completa y próximos pasos

### 4. **SIGUIENTES_PASOS.md**
Plan de acción inmediato para implementar el Search & Pricing Microservice. Incluye código de ejemplo, cronograma y criterios de éxito.

**Cuándo leerlo:** Antes de empezar a trabajar en Search Microservice

---

## 🔧 DOCUMENTOS TÉCNICOS

### 5. **documentacion.md**
Especificación técnica original completa del proyecto. Stack, arquitectura de bounded contexts, DDL de bases de datos, tópicos Kafka, patrones.

**Cuándo leerlo:** Para entender las decisiones arquitectónicas originales

### 6. **BOOKING_SERVICE_COMPLETADO.md**
Documentación técnica completa del Booking Microservice. Estructura del código, patrón Outbox, eventos Kafka, endpoints.

**Cuándo leerlo:** Para trabajar en o entender el Booking Service

### 7. **GUIA_SCRIPTS.md**
Guía completa de todos los scripts de arranque del proyecto.

**Cuándo leerlo:** Para levantar la infraestructura y servicios

---

## 📋 DOCUMENTOS DE REFERENCIA

### 8. **QUICKSTART.md**
Guía rápida de inicio (puede estar desactualizada, usar README.md en su lugar)

### 9. **REDIS_COMPLETO.md**
Documentación sobre Redis y su uso en el proyecto

### 10. **RESUMEN_EJECUTIVO.md**
Resumen ejecutivo del proyecto (puede estar desactualizado)

### 11. **TESTING.md**
Estrategias de testing (por desarrollar)

---

## 📂 ESTRUCTURA DE ARCHIVOS

```
BalconazoApp/
├── README.md                         ⭐ INICIO AQUÍ
├── ESTADO_ACTUAL.md                  Estado del proyecto
├── HOJA_DE_RUTA.md                   Roadmap completo
├── SIGUIENTES_PASOS.md               Plan Search Microservice
├── GUIA_SCRIPTS.md                   Guía de scripts
├── BOOKING_SERVICE_COMPLETADO.md     Docs Booking Service
├── documentacion.md                  Especificación técnica original
├── QUICKSTART.md                     Guía rápida
├── REDIS_COMPLETO.md                 Docs Redis
├── RESUMEN_EJECUTIVO.md              Resumen ejecutivo
└── TESTING.md                        Estrategias de testing
```

---

## 🎯 FLUJO DE LECTURA RECOMENDADO

### Para nuevos desarrolladores:

1. **README.md** - Entender qué es el proyecto
2. **ESTADO_ACTUAL.md** - Ver qué está funcionando
3. **GUIA_SCRIPTS.md** - Levantar el proyecto localmente
4. Ejecutar `./test-e2e.sh` - Probar el flujo completo
5. **BOOKING_SERVICE_COMPLETADO.md** - Entender un microservicio completo
6. **SIGUIENTES_PASOS.md** - Ver qué implementar siguiente

### Para continuar el desarrollo:

1. **SIGUIENTES_PASOS.md** - Plan del Search Microservice
2. **HOJA_DE_RUTA.md** - Visión completa del proyecto
3. **documentacion.md** - Especificación técnica detallada

### Para deployment:

1. **HOJA_DE_RUTA.md** (Fase 5) - Plan de despliegue AWS
2. **documentacion.md** - Configuración de infraestructura

---

## 🔍 BÚSQUEDA RÁPIDA

### ¿Cómo levantar el proyecto?
👉 **README.md** (sección Quick Start) o **GUIA_SCRIPTS.md**

### ¿Qué está funcionando ahora?
👉 **ESTADO_ACTUAL.md**

### ¿Cómo crear una reserva?
👉 **README.md** (sección Endpoints API → Booking Service)

### ¿Cómo funciona el Outbox Pattern?
👉 **BOOKING_SERVICE_COMPLETADO.md** (sección Patrón Outbox)

### ¿Qué endpoints hay disponibles?
👉 **README.md** (sección Endpoints API) o **ESTADO_ACTUAL.md**

### ¿Cómo ver eventos en Kafka?
👉 **ESTADO_ACTUAL.md** (sección Comandos útiles)

### ¿Qué implementar siguiente?
👉 **SIGUIENTES_PASOS.md**

### ¿Cuál es el plan completo?
👉 **HOJA_DE_RUTA.md**

### ¿Cómo hacer pruebas E2E?
👉 **GUIA_SCRIPTS.md** o ejecutar `./test-e2e.sh`

---

## 📊 ESTADO DE DOCUMENTACIÓN

| Documento | Estado | Última actualización |
|-----------|--------|---------------------|
| README.md | ✅ Actualizado | 28 Oct 2025 |
| ESTADO_ACTUAL.md | ✅ Actualizado | 28 Oct 2025 |
| HOJA_DE_RUTA.md | ✅ Actualizado | 28 Oct 2025 |
| SIGUIENTES_PASOS.md | ✅ Actualizado | 28 Oct 2025 |
| GUIA_SCRIPTS.md | ✅ Actualizado | 28 Oct 2025 |
| BOOKING_SERVICE_COMPLETADO.md | ✅ Actualizado | 28 Oct 2025 |
| documentacion.md | ⚠️ Original | - |
| QUICKSTART.md | ⚠️ Puede estar desactualizado | - |
| REDIS_COMPLETO.md | ⚠️ Referencia | - |
| RESUMEN_EJECUTIVO.md | ⚠️ Puede estar desactualizado | - |
| TESTING.md | ⏳ Por desarrollar | - |

---

## 🗑️ DOCUMENTOS ELIMINADOS (obsoletos)

Los siguientes documentos fueron eliminados por ser temporales o redundantes:

- ❌ KAFKA_SETUP.md (info redundante con ESTADO_ACTUAL.md)
- ❌ SESION_COMPLETADA.md (temporal)
- ❌ KAFKA_HEALTH_CHECK.md (ya implementado)
- ❌ KAFKA_HEALTH_IMPLEMENTADO.md (temporal)
- ❌ SIGUIENTE_PASO.md (sustituido por SIGUIENTES_PASOS.md)
- ❌ RESUMEN_SESION_BOOKING.md (temporal)

---

## 📝 CONTRIBUIR A LA DOCUMENTACIÓN

Si actualizas la documentación:

1. Actualiza la fecha en el documento
2. Actualiza este índice si es necesario
3. Marca el documento como ✅ Actualizado en la tabla de estado

---

**Última actualización de este índice:** 28 de Octubre de 2025

