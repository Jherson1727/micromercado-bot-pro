# Sistema Automatizado de Ventas - Micromercado "Preciazo"

## Ecosistema Transaccional con Inteligencia Artificial  
**Dify + Node.js + MySQL + Cloudflare**

Bienvenido al repositorio oficial del **Sistema Conversacional del Micromercado Preciazo**.  
Este proyecto integra un agente de Inteligencia Artificial capaz de procesar lenguaje natural, consultar inventarios en tiempo real y ejecutar transacciones directamente sobre una base de datos relacional robusta, segura y automatizada.

---

## Arquitectura del Proyecto

El sistema está diseñado bajo una arquitectura desacoplada, orientada a servicios y eventos, con separación clara de responsabilidades.

### Componentes del sistema

- **Frontend / Capa de IA (`/dify-bot`)**  
  Orquestador en Dify que gestiona NLP, memoria conversacional y enrutamiento lógico de intenciones.

- **Backend / API REST (`/backend-api`)**  
  Servidor desarrollado en Node.js + Express que expone endpoints REST, aplica reglas de negocio y validaciones de seguridad.

- **Capa de Datos (`/base-de-datos`)**  
  Base de datos MySQL (`caja_chica_pro`) con tablas normalizadas, vistas optimizadas y triggers automáticos para Kardex, stock y fiados.

- **Seguridad y Conectividad (Cloudflare)**  
  Túnel HTTPS seguro que conecta la IA en la nube con el backend local sin exponer puertos ni direcciones IP.

---

## Estructura del Repositorio

```text
├── backend-api/          # Código fuente de la API REST (Node.js + Express)
├── base-de-datos/        # Script SQL (.sql) y modelo de datos (.mwb)
└── dify-bot/             # Archivo DSL (.yml) del agente de IA
```

---

## 🚀 Guía de Instalación y Despliegue

Guía completa para instalar, configurar y desplegar todo el ecosistema del sistema.

### 1 ase de Datos (MySQL)

1. Dirígete a la carpeta `/base-de-datos`.
2. Abre tu gestor de MySQL (Workbench, phpMyAdmin o consola).
3. Ejecuta el script `caja_chica_pro.sql`.

Este script crea automáticamente:
- La base de datos `caja_chica_pro`
- Tablas de productos, ventas, clientes, kardex y fiados
- Vistas optimizadas
- Triggers automáticos para descuento de stock y control contable

Resultado: base de datos lista para operar sin lógica adicional.

---

### 2 Backend – API REST (Node.js + Express)

1. Accede a la carpeta `/backend-api`.
2. Instala dependencias:
   ```bash
   npm install
   ```
3. Configura el archivo `.env`:
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_USER=tu_usuario_mysql
   DB_PASSWORD=tu_password_mysql
   DB_NAME=caja_chica_pro
   ```
4. Inicia el servidor:
   ```bash
   node server.js
   ```

El backend quedará activo en `http://localhost:3000`.

---

### 3 Conectividad Segura – Cloudflare Tunnel

Expón el backend de forma segura mediante HTTPS:

```bash
cloudflared tunnel run <tu-tunel>
```

Cloudflare generará una URL pública HTTPS que será utilizada por el agente de IA.

---

### 4 Agente de IA – Dify

1. Ingresa a tu panel de Dify.
2. Selecciona **Crear App → Importar desde archivo DSL**.
3. Importa el archivo `.yml` ubicado en `/dify-bot`.
4. Configura las herramientas `buscarProductos` y `registrarVenta` apuntando a la URL HTTPS de Cloudflare.

El agente queda conectado en tiempo real al backend y a la base de datos.

---

##  Casos de Uso Validados

###  Consulta Dinámica de Inventario (GET)

- El usuario consulta un producto en lenguaje natural.
- La IA interpreta la intención.
- El backend consulta MySQL.
- Se devuelve stock real y precio actualizado.

---

###  Control de Quiebre de Stock (Edge Case)

- Si `stock_actual = 0`:
  - El backend bloquea la operación.
  - La IA responde diplomáticamente indicando que el producto está agotado.
  - Se evita una transacción inválida.

---

###  Persistencia de Venta Completa (POST)

- El usuario confirma la compra.
- Se registra la venta con ID de producto y cantidad.
- Los triggers de MySQL:
  - Descuentan stock automáticamente
  - Actualizan el Kardex
  - Registran movimientos contables

No se requiere lógica adicional para inventarios en el backend.

---

##  ¿Por qué este proyecto destaca?

Este repositorio demuestra:
- Arquitectura real de producción
- Integración efectiva de IA con sistemas transaccionales
- Separación clara de capas (IA, API, BD)
- Automatización a nivel de base de datos
- Documentación clara y profesional

Este archivo funciona como documentación técnica, guía de despliegue y marco teórico del proyecto.

---


