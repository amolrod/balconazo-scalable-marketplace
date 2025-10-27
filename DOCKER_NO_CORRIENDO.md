# 🐳 SOLUCIÓN - Docker no está corriendo

## ❌ Error Detectado

```
Cannot connect to the Docker daemon at unix:///Users/angel/.docker/run/docker.sock
Is the docker daemon running?
```

## 🔧 SOLUCIÓN INMEDIATA

### Paso 1: Iniciar Docker Desktop

1. **Abre Docker Desktop** desde tu carpeta de Aplicaciones
   - Ve a `Aplicaciones` → `Docker`
   - O usa Spotlight (Cmd + Space) y escribe "Docker"

2. **Espera a que Docker se inicie** (ícono de ballena en la barra superior)
   - Verás el ícono de Docker en la barra de menú superior
   - Espera hasta que deje de parpadear y se quede quieto
   - Puede tardar 30-60 segundos

3. **Verifica que Docker está corriendo**
   ```bash
   docker ps
   ```
   
   Si funciona, verás algo como:
   ```
   CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
   ```

---

## 🚀 PASOS DESPUÉS DE INICIAR DOCKER

### 1. Levantar PostgreSQL

```bash
docker run -d --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:16-alpine
```

### 2. Verificar que PostgreSQL está corriendo

```bash
docker ps | grep postgres
```

Deberías ver:
```
balconazo-pg-catalog   postgres:16-alpine   Up X seconds   0.0.0.0:5433->5432/tcp
```

### 3. Esperar 5-10 segundos para que PostgreSQL inicie

```bash
sleep 10
```

### 4. Ejecutar el servicio catalog

```bash
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run
```

---

## ✅ Verificación Rápida

### Verificar Docker
```bash
docker --version
docker ps
```

### Verificar PostgreSQL
```bash
docker logs balconazo-pg-catalog | grep "ready to accept"
```

Deberías ver:
```
database system is ready to accept connections
```

### Verificar conexión a la base de datos
```bash
docker exec -it balconazo-pg-catalog psql -U postgres -d catalog_db -c "SELECT version();"
```

---

## 🆘 Si Docker Desktop no arranca

### Opción A: Reiniciar Docker Desktop
1. Cierra Docker Desktop completamente
2. Abre el Monitor de Actividad (Activity Monitor)
3. Busca procesos de "Docker" y forzar salir si existen
4. Vuelve a abrir Docker Desktop

### Opción B: Reiniciar Mac
Si Docker sigue sin funcionar, reinicia tu Mac.

### Opción C: Reinstalar Docker Desktop
1. Descarga desde: https://www.docker.com/products/docker-desktop
2. Instala la última versión

---

## 📋 CHECKLIST COMPLETO

- [ ] Docker Desktop iniciado
- [ ] Ícono de Docker en la barra superior (ballena)
- [ ] `docker ps` funciona sin errores
- [ ] PostgreSQL levantado con `docker run`
- [ ] `docker ps` muestra balconazo-pg-catalog
- [ ] Esperado 10 segundos para que PostgreSQL inicie
- [ ] Ejecutar `mvn spring-boot:run`
- [ ] Servicio inicia en puerto 8081
- [ ] Health check funciona: `curl http://localhost:8081/actuator/health`

---

## 🎯 SIGUIENTE PASO

**Una vez que Docker Desktop esté corriendo:**

```bash
# 1. Levantar PostgreSQL
docker run -d --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:16-alpine

# 2. Esperar que inicie
sleep 10

# 3. Ejecutar servicio
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run
```

---

## 💡 ALTERNATIVA: Sin Docker (PostgreSQL local)

Si prefieres no usar Docker, puedes instalar PostgreSQL localmente:

```bash
# Instalar con Homebrew
brew install postgresql@16

# Iniciar PostgreSQL
brew services start postgresql@16

# Crear base de datos
createdb catalog_db

# Modificar application.yml para usar localhost:5432
```

Luego cambia en `application.yml`:
```yaml
datasource:
  url: jdbc:postgresql://localhost:5432/catalog_db
  username: tu_usuario_mac
  password: ""
```

---

**Estado:** ⏸️ Esperando que inicies Docker Desktop  
**Próximo paso:** Ejecutar los comandos de arriba después de iniciar Docker

