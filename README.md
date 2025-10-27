# 🏠 BALCONAZO - Marketplace de Espacios

> Plataforma de alquiler de balcones y terrazas para eventos privados

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-brightgreen)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange)](https://openjdk.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org/)
[![Kafka](https://img.shields.io/badge/Kafka-3.7-black)](https://kafka.apache.org/)
[![Docker](https://img.shields.io/badge/Docker-latest-blue)](https://www.docker.com/)

---

## 📋 Tabla de Contenidos

- [Sobre el Proyecto](#sobre-el-proyecto)
- [Estado Actual](#estado-actual)
- [Arquitectura](#arquitectura)
- [Tecnologías](#tecnologías)
- [Instalación](#instalación)
- [Uso](#uso)
- [Documentación](#documentación)
- [Roadmap](#roadmap)

---

## 📖 Sobre el Proyecto

**Balconazo** es un marketplace que conecta propietarios de balcones y terrazas con personas que buscan espacios únicos para eventos privados (fiestas, reuniones, cenas, etc.).

### Características Principales

- ✅ Gestión de usuarios (hosts y guests)
- ✅ Catálogo de espacios con geolocalización
- ✅ Sistema de disponibilidad temporal
- ⏳ Reservas con pago integrado
- ⏳ Búsqueda geoespacial avanzada
- ⏳ Pricing dinámico basado en demanda
- ⏳ Sistema de reviews y reputación
- ⏳ Notificaciones en tiempo real

---

## ✅ Estado Actual

### Completado (27 Oct 2025)

- ✅ **catalog-service** - Microservicio funcionando al 100%
  - Puerto: 8085
  - Endpoints REST: Users, Spaces, Availability
  - PostgreSQL: Conectado y tablas creadas
  - Kafka Producers: Implementados
  - Health Check: ✅ UP

### En Progreso

- ⏳ Kafka + Zookeeper (próximo paso)
- ⏳ booking-service (siguiente microservicio)
- ⏳ search-pricing-service

### Pendiente

- ⏸️ API Gateway (Spring Cloud Gateway)
- ⏸️ Frontend Angular 20
- ⏸️ Redis (cache y locks)
- ⏸️ Deployment AWS

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────┐
│            Angular Frontend :4200                    │
└──────────────────┬───────────────────────────────────┘
                   │ HTTPS/JWT
                   ▼
┌──────────────────────────────────────────────────────┐
│       Spring Cloud Gateway :8080 (⏸️ TODO)          │
└──────────────────┬───────────────────────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
   ┌────────┐ ┌────────┐ ┌────────┐
   │Catalog │ │Booking │ │ Search │
   │:8081   │ │:8082   │ │:8083   │
   │✅ UP   │ │⏳ TODO │ │⏳ TODO │
   └───┬────┘ └───┬────┘ └───┬────┘
       │          │          │
       ▼          ▼          ▼
   ┌────────┐ ┌────────┐ ┌────────┐
   │PG:5433 │ │PG:5434 │ │PG:5435 │
   │✅ UP   │ │⏸️ TODO │ │⏸️ TODO │
   └────────┘ └────────┘ └────────┘

       │          │          │
       └──────────┼──────────┘
                  │
         ┌────────▼────────┐
         │  Kafka :9092    │
         │  ⏳ TODO        │
         └─────────────────┘
```

### Microservicios

1. **catalog-service** ✅ - Usuarios, Espacios, Disponibilidad
2. **booking-service** ⏳ - Reservas, Pagos, Reviews
3. **search-pricing-service** ⏳ - Búsqueda geoespacial, Pricing dinámico

---

## 🛠️ Tecnologías

### Backend
- **Spring Boot** 3.5.7
- **Java** 21
- **PostgreSQL** 16
- **Apache Kafka** 3.7
- **Redis** 7
- **Maven** 3.9+

### Frontend (Pendiente)
- **Angular** 20
- **Tailwind CSS**
- **TypeScript**

### DevOps
- **Docker** & Docker Compose
- **AWS** ECS/EKS (producción)
- **GitHub Actions** (CI/CD)

---

## 🚀 Instalación

### Requisitos Previos

- Java 21
- Maven 3.9+
- Docker Desktop
- PostgreSQL client (opcional)

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/balconazo-app.git
cd balconazo-app
```

### Paso 2: Levantar PostgreSQL

```bash
docker run -d \
  --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:16-alpine

# Crear schema
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c "CREATE SCHEMA IF NOT EXISTS catalog;"
```

### Paso 3: Compilar el Proyecto

```bash
cd catalog_microservice
mvn clean install -DskipTests
```

### Paso 4: Arrancar catalog-service

```bash
mvn spring-boot:run
```

El servicio estará disponible en: `http://localhost:8085`

### Paso 5: Verificar Health Check

```bash
curl http://localhost:8085/actuator/health
```

Respuesta esperada:
```json
{
  "status": "UP"
}
```

---

## 📝 Uso

### Crear un Usuario

```bash
curl -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host@balconazo.com",
    "password": "password123",
    "role": "host"
  }'
```

### Crear un Espacio

```bash
curl -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "uuid-del-usuario",
    "title": "Terraza con vistas al Retiro",
    "description": "Amplia terraza de 50m²",
    "address": "Calle Alcalá 123, Madrid",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 20,
    "areaSqm": 50.0,
    "basePriceCents": 15000,
    "amenities": ["wifi", "barbecue"],
    "rules": {"no_smoking": true}
  }'
```

### Listar Espacios

```bash
curl http://localhost:8085/api/catalog/spaces
```

Ver más ejemplos en [`TESTING.md`](./TESTING.md)

---

## 📚 Documentación

- **[documentacion.md](./documentacion.md)** - Documentación técnica completa
- **[TESTING.md](./TESTING.md)** - Guía de pruebas y ejemplos
- **[QUICKSTART.md](./QUICKSTART.md)** - Guía rápida de inicio
- **[README.md](./README.md)** - Este archivo

---

## 🗺️ Roadmap

### Fase 1: Backend Core (EN PROGRESO)
- [x] Setup inicial del proyecto
- [x] catalog-service funcional
- [ ] Levantar Kafka
- [ ] Implementar booking-service
- [ ] Implementar search-pricing-service
- [ ] API Gateway

### Fase 2: Integración
- [ ] Redis para cache
- [ ] Saga de booking
- [ ] Motor de pricing dinámico
- [ ] Integración con Stripe

### Fase 3: Frontend
- [ ] Setup Angular 20
- [ ] Páginas principales
- [ ] Autenticación JWT
- [ ] Integración con API

### Fase 4: Producción
- [ ] Docker Compose completo
- [ ] CI/CD
- [ ] Deployment AWS
- [ ] Monitoring

---

## 🤝 Contribuir

Este es un proyecto educacional. Si encuentras bugs o tienes sugerencias:

1. Abre un issue
2. Haz un fork del proyecto
3. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
4. Commit tus cambios (`git commit -m 'Añade nueva funcionalidad'`)
5. Push a la rama (`git push origin feature/nueva-funcionalidad`)
6. Abre un Pull Request

---

## 📄 Licencia

Este proyecto es de código abierto bajo la licencia MIT.

---

## 👨‍💻 Autor

**Angel Rodriguez**

- GitHub: [@amolrod](https://github.com/amolrod)
- Email: angel@balconazo.com

---

## 🙏 Agradecimientos

- Spring Framework Team
- Apache Kafka Community
- PostgreSQL Team

---

**¡Gracias por tu interés en Balconazo!** 🚀🎉

---

**Última actualización:** 27 de octubre de 2025  
**Estado:** catalog-service ✅ Funcional

