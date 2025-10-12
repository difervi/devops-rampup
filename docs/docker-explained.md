# Explicación: uso de Docker para levantar la aplicación "devops-rampup"

Este documento describe por qué usamos Docker para ejecutar localmente la aplicación del repositorio `devops-rampup`, qué decisiones tomamos, los comandos exactos que ejecutaste, y cómo reproducirlos. Está pensado para incluirlo en la documentación del proyecto y poder generar un PDF para entrega al cliente.

## Resumen ejecutivo

- Se decidió usar Docker para evitar instalar dependencias en Windows (Node.js, MySQL) y para aislar el entorno de ejecución.
- El repositorio no incluía contenedores listos (no había Dockerfile ni `docker-compose.yml`), pero sí mostraba que la aplicación es Node (frontend y backend) y depende de una base de datos MySQL.
- Levantamos los servicios dentro de contenedores Docker y los conectamos mediante una red Docker (`movie-net`). Esto permitió usar nombres DNS internos (por ejemplo `movie-mysql`) como `DB_HOST` sin cambiar el código.
- Mapeamos MySQL al puerto host `3307` porque el puerto `3306` ya estaba en uso en la máquina; internamente MySQL siguió usando el puerto `3306`.

## Por qué Docker

1. Reproducibilidad: el contenedor usa una imagen oficial (`node:18`, `mysql:5.7`) garantizando versiones conocidas de runtime.
2. Aislamiento: evita conflictos con software instalado en Windows (versiones de Node, MySQL locales, etc.).
3. Rapidez: levantar y destruir entornos de prueba con `docker run` y `docker rm -f` es rápido y limpio.
4. Reducción de cambios al código: usándolo en la misma red Docker se puede apuntar `DB_HOST` a `movie-mysql` sin editar `server.js`.

## Decisiones y justificación técnica

- Red Docker (`movie-net`): facilita la resolución por nombre entre contenedores y evita tocar variables de puerto en el código.
- Mapeo de puertos: se asignó `3307:3306` para MySQL para evitar conflictos con servicios locales en el host. El backend y frontend se ejecutaron en contenedores conectados a la misma red y se exponen en el host en los puertos `3000` (backend) y `3030` (frontend).
- Seeds y esquema: el repo incluía `seeds.js` pero no `.sql` con schema, por tanto se creó el esquema mínimo (tablas `publications`, `reviewers`, `movies`) dentro del contenedor MySQL antes de ejecutar `seeds.js`.
- Evitar modificar el repo: usamos `--tmpfs /app/node_modules` y `npm install --no-package-lock` para que `npm` no escriba `node_modules` ni `package-lock.json` en el árbol del repo.
- Manejo de rutas en Windows/Git Bash: usamos `MSYS_NO_PATHCONV=1` y `$(pwd -W)` al montar volúmenes para evitar la conversión automática de rutas MSYS que rompía `-v`.

## Comandos reproducibles (ejecutados en Git Bash)

> Nota: los comandos están diseñados para no modificar el repo y para ejecutarse desde la raíz del repo `devops-rampup`.

1. Crear la red Docker (solo la primera vez):

```bash
docker network create movie-net || true
```

2. Arrancar MySQL (evita conflicto en 3306, mapeando al host 3307):

```bash
docker run --name movie-mysql \
  --network movie-net \
  -e MYSQL_ROOT_PASSWORD=rootpwd \
  -e MYSQL_DATABASE=movie_db \
  -e MYSQL_USER=applicationuser \
  -e MYSQL_PASSWORD=applicationuser \
  -p 3307:3306 \
  -d mysql:5.7
```

3. Verificar logs (esperar "ready for connections"):

```bash
docker logs -f movie-mysql
# Ctrl+C para salir
```

4. Crear tablas (heredoc, no se crean archivos en el repo):

```bash
docker exec -i movie-mysql mysql -u root -prootpwd movie_db <<'SQL'
CREATE TABLE IF NOT EXISTS publications (
  name VARCHAR(255) NOT NULL PRIMARY KEY,
  avatar VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS reviewers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255),
  publication VARCHAR(255),
  avatar VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS movies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255),
  release_year INT,
  score INT,
  reviewer VARCHAR(255),
  publication VARCHAR(255)
);
SQL
```

5. Ejecutar seeds (usar contenedor node temporal y la red Docker)

> En Git Bash conviene usar `MSYS_NO_PATHCONV=1` para evitar problemas de ruta al montar volúmenes.

```bash
MSYS_NO_PATHCONV=1 docker run --rm --network movie-net -v "$(pwd -W)/movie-analyst-api":/app -w /app \
  -e DB_HOST=movie-mysql -e DB_USER=applicationuser -e DB_PASS=applicationuser -e DB_NAME=movie_db \
  node:18 bash -c "npm install --no-package-lock && node seeds.js"
```

6. Levantar backend y frontend en contenedores (evita instalación local de Node):

```bash
MSYS_NO_PATHCONV=1 docker run -d --name movie-backend \
  --network movie-net \
  -p 3000:3000 \
  -v "$(pwd -W)/movie-analyst-api":/app \
  --tmpfs /app/node_modules \
  -w /app \
  -e DB_HOST=movie-mysql \
  -e DB_USER=applicationuser \
  -e DB_PASS=applicationuser \
  -e DB_NAME=movie_db \
  -e PORT=3000 \
  node:18 \
  bash -c "npm install --no-package-lock && node server.js"

MSYS_NO_PATHCONV=1 docker run -d --name movie-frontend \
  --network movie-net \
  -p 3030:3030 \
  -v "$(pwd -W)/movie-analyst-ui":/app \
  --tmpfs /app/node_modules \
  -w /app \
  -e BACKEND_URL=movie-backend:3000 \
  -e PORT=3030 \
  node:18 \
  bash -c "npm install --no-package-lock && node server.js"
```

7. Probar endpoints:

```bash
curl -i http://localhost:3000/
curl -i http://localhost:3030/movies
```

8. Limpieza (cuando termines):

```bash
docker rm -f movie-frontend movie-backend movie-mysql || true
docker network rm movie-net || true
```

## Posibles mejoras y artefactos sugeridos

- Añadir `Dockerfile` y `docker-compose.yml` al repo para facilitar `docker-compose up --build` y documentar el flujo para otros desarrolladores.
- Persistencia MySQL: usar volumen nombrado `-v movie-mysql-data:/var/lib/mysql` para mantener datos entre reinicios.
- Crear un `Makefile` o `scripts/` con comandos reproducibles (start, stop, seed, clean).

## Cómo generar el PDF (instrucciones para el equipo)

1. Requisitos: `pandoc` (recomendado) o `wkhtmltopdf`. En Windows puedes instalar Pandoc desde https://pandoc.org/installing.html.
2. Desde la raíz del repo ejecutar (PowerShell):

```powershell
pwsh scripts\generate-pdf.ps1 -SourceFile docs\docker-explained.md -OutFile docs\docker-explained.pdf
```

El script `scripts/generate-pdf.ps1` que acompaña este documento detectará `pandoc` o `wkhtmltopdf` y usará el disponible.

## Entregables

- `docs/docker-explained.md` — (este archivo) explicación completa para el proyecto.
- `scripts/generate-pdf.ps1` — script PowerShell para convertir el Markdown a PDF localmente.

---

Si quieres, puedo también generar un `docker-compose.yml` y un `Makefile` de ejemplo y guardarlos en el repo como sugerencia para tu entrega. ¿Los creamos ahora?