# 🏠 BalconazoApp - Plataforma de Alquiler de Espacios

[![Estado](https://img.shields.io/badge/Estado-Producción%20Ready-success)](.)
[![Tests](https://img.shields.io/badge/Tests-27%2F27%20Passing-brightgreen)](.)
[![Java](https://img.shields.io/badge/Java-21-orange)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-green)](https://spring.io/projects/spring-boot)

> Sistema de microservicios para alquiler de balcones, terrazas y patios. Backend completo y funcional al 100%.

## 🚀 Inicio Rápido

```bash
# 1. Iniciar infraestructura (DBs, Kafka, Redis)
./start-infrastructure.sh

# 2. Compilar y iniciar sistema completo
./start-system-improved.sh

# 3. Verificar estado
./verify-system.sh

# 4. Ejecutar tests E2E (27 tests)
./test-e2e-completo.sh
```

**URLs principales:**
- API Gateway: http://localhost:8080
- Eureka Dashboard: http://localhost:8761
- Swagger UI: http://localhost:8080/swagger-ui.html

## 📋 Características

✅ **Autenticación JWT** - Segura con Spring Security  
✅ **CRUD de Espacios** - Gestión completa  
✅ **Sistema de Reservas** - Con confirmación de pago  
✅ **Búsqueda Geoespacial** - PostGIS para ubicaciones  
✅ **Eventos Kafka** - Comunicación asíncrona  
✅ **API Gateway** - Spring Cloud Gateway  
✅ **Service Discovery** - Eureka Server  
✅ **Métricas** - Actuator + Prometheus

## 🏗️ Arquitectura

```
API Gateway (8080) → [ Auth (8084) | Catalog (8085) | Booking (8082) | Search (8083) ]
                        ↓
                    Eureka Server (8761)
                        ↓
            [ MySQL | PostgreSQL | Redis | Kafka ]
```

**Microservicios:**
- **Auth Service** (8084) - Autenticación JWT + MySQL
- **Catalog Service** (8085) - Gestión de espacios + PostgreSQL
- **Booking Service** (8082) - Reservas + PostgreSQL
- **Search Service** (8083) - Búsqueda geoespacial + PostGIS

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| [Guía de Inicio Rápido](docs/guides/GUIA_INICIO_RAPIDO.md) | Tutorial completo paso a paso |
| [Guía de Scripts](docs/guides/GUIA_SCRIPTS.md) | Todos los scripts disponibles |
| [Quick Start](docs/guides/QUICKSTART.md) | Inicio en 5 minutos |
| [Estado del Sistema](docs/technical/SISTEMA_100_FUNCIONAL.md) | Funcionalidades completas |
| [API Gateway](docs/technical/API_GATEWAY_COMPLETADO.md) | Arquitectura del Gateway |
| [Hoja de Ruta](docs/HOJA_DE_RUTA.md) | Roadmap del proyecto |
| [Próximos Pasos](docs/NEXT_STEPS.md) | Plan de desarrollo |

Ver [documentación completa](docs/) para más detalles.

## 🛠️ Scripts Principales

```bash
# Gestión del sistema
./start-system-improved.sh   # Inicia todo (infraestructura + servicios)
./stop-all.sh                # Detiene todo
./recompile-all.sh           # Recompila todos los microservicios

# Verificación
./verify-system.sh           # Health checks completos
./check-system.sh            # Verificación rápida

# Testing
./test-e2e-completo.sh       # Suite E2E (27 tests)
./test-redis.sh              # Tests de Redis

# Servicios individuales
./start-eureka.sh            # Solo Eureka Server
./start-gateway.sh           # Solo API Gateway
./start-catalog.sh           # Solo Catalog Service
# ... (ver docs/guides/GUIA_SCRIPTS.md)
```

## 🔧 Prerequisitos

- **Java 21+**
- **Maven 3.8+**
- **Docker 24+**
- **Docker Compose 2.0+**

## 📊 Estado Actual

```
✅ Backend: 100% Funcional (27/27 tests)
✅ Microservicios: 5/5 operativos
✅ API Gateway: Funcionando
✅ Eureka: Activo
✅ Kafka: Eventos propagando
✅ Tests E2E: 100% pasando
```

## 🐛 Troubleshooting

**Servicios no inician:**
```bash
./check-system.sh           # Ver estado
tail -f /tmp/*.log          # Ver logs
./stop-all.sh && ./start-system-improved.sh  # Reiniciar
```

**Tests fallan:**
```bash
curl http://localhost:8080/actuator/health  # Verificar gateway
curl http://localhost:8761/eureka/apps      # Ver servicios registrados
```

Ver [Diagnóstico y Solución](docs/technical/DIAGNOSTICO_Y_SOLUCION_FINAL.md) para más ayuda.

## 🚦 Próximas Funcionalidades

**Corto Plazo:**
- Frontend Angular 20
- Integración Stripe para pagos
- Sistema de reviews

**Medio Plazo:**
- Chat en tiempo real (WebSocket)
- Panel de administración
- Notificaciones push

Ver [NEXT_STEPS.md](docs/NEXT_STEPS.md) para plan completo.

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE)

## 📞 Contacto

- Email: contacto@balconazo.com
- Issues: https://github.com/tu-usuario/BalconazoApp/issues

---

**Versión:** 1.1.0  
**Última Actualización:** 29 de Octubre de 2025  
**Estado:** 🟢 Producción Ready

