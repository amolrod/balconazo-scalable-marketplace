# 🚀 QUICKSTART - Balconazo

> Guía rápida para levantar el proyecto en **menos de 10 minutos**

---

## ✅ Pre-requisitos

```bash
# Verificar versiones
java -version          # Java 21+
mvn -version          # Maven 3.9+
docker --version      # Docker 24+
```

---

## 🎯 Instalación Rápida (3 pasos)

### 1️⃣ Levantar PostgreSQL

```bash
docker run -d \
  --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:16-alpine

# Esperar 10 segundos
sleep 10

# Crear schema
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db \
  -c "CREATE SCHEMA IF NOT EXISTS catalog;"
```

### 2️⃣ Compilar y Arrancar catalog-service

```bash
cd catalog_microservice
mvn clean install -DskipTests
mvn spring-boot:run
```

**Espera a ver:**
```
Started CatalogMicroserviceApplication in X.XXX seconds
```

### 3️⃣ Verificar que Funciona

```bash
# Health check
curl http://localhost:8085/actuator/health

# Debería responder:
# {"status":"UP"}
```

---

## 🧪 Prueba Rápida

### Crear un Usuario

```bash
curl -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host@test.com",
    "password": "test123",
    "role": "host"
  }'
```

**Respuesta:**
```json
{
  "id": "uuid-generado",
  "email": "host@test.com",
  "role": "host",
  "status": "ACTIVE"
}
```

### Crear un Espacio

```bash
# Reemplaza USUARIO_UUID con el id del usuario anterior
curl -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "USUARIO_UUID",
    "title": "Terraza Madrid Centro",
    "description": "Bonita terraza en el centro",
    "address": "Calle Mayor 1, Madrid",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 15,
    "areaSqm": 30.0,
    "basePriceCents": 10000,
    "amenities": ["wifi"],
    "rules": {"no_smoking": true}
  }'
```

### Listar Espacios

```bash
curl http://localhost:8085/api/catalog/spaces
```

---

## 🛑 Detener Todo

```bash
# Detener Spring Boot (Ctrl+C en la terminal)

# Detener PostgreSQL
docker stop balconazo-pg-catalog
docker rm balconazo-pg-catalog
```

---

## 🔧 Troubleshooting

### Error: "Port 8085 already in use"
```bash
# Buscar proceso usando el puerto
lsof -i :8085

# Matar proceso
kill -9 <PID>
```

### Error: "Cannot connect to PostgreSQL"
```bash
# Verificar que PostgreSQL está corriendo
docker ps | grep balconazo-pg-catalog

# Ver logs
docker logs balconazo-pg-catalog

# Reiniciar contenedor
docker restart balconazo-pg-catalog
```

### Error: "password authentication failed"
```bash
# Eliminar y recrear PostgreSQL
docker rm -f balconazo-pg-catalog
docker volume rm -f pg-catalog-data

# Volver a ejecutar el comando del paso 1
```

---

## 📚 Próximos Pasos

1. ✅ catalog-service funcionando
2. ⏭️ Levantar Kafka (ver [documentacion.md](./documentacion.md))
3. ⏭️ Implementar booking-service
4. ⏭️ Implementar search-pricing-service
5. ⏭️ Frontend Angular

---

## 🆘 ¿Necesitas Ayuda?

- **Documentación completa:** [`documentacion.md`](./documentacion.md)
- **Guía de pruebas:** [`TESTING.md`](./TESTING.md)
- **README principal:** [`README.md`](./README.md)

---

**¡Listo para comenzar!** 🚀

**Última actualización:** 27 de octubre de 2025

