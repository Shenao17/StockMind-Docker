# StockMind — Roadmap, Errores Conocidos y Decisiones Técnicas

> Documento de referencia interna para el equipo de desarrollo.  
> Refleja el estado real del sistema, decisiones arquitectónicas tomadas, bugs abiertos y funcionalidades planificadas.

---

## Estado actual: v1.2.0 (experimental)

| Componente | Estado |
|-----------|--------|
| Frontend React 18 + Vite | ✅ Estable |
| Gateway Node.js | ✅ Estable |
| Backend Java Spring Boot | ✅ Estable |
| Microservicio Python Flask | ✅ Estable |
| Agente IA (AgentBubble) | ⚗️ Experimental |

---

## Errores conocidos y abiertos

### 🔴 ERR-001 — El sistema no inicia en otros equipos (causa desconocida)

**Descripción:** Al clonar el repositorio en un equipo distinto al de desarrollo y ejecutar `start.bat`, el sistema no arranca correctamente. El error no es consistente ni descriptivo.

**Comportamiento observado:** Los servicios aparentan levantarse pero el login falla o la aplicación no carga en el navegador.

**Hipótesis activas:**
- Versión de Java distinta a 17 LTS instalada en el equipo destino
- Puerto 3000, 8080 o 8000 ocupado por otro proceso
- MySQL no está corriendo o las credenciales en `application.properties` y `config.py` no fueron configuradas correctamente a partir de los `.example`
- Variable `JWT_SECRET` distinta entre `gateway/.env` y `application.properties`
- `JAVA_HOME` no configurado en las variables de entorno del sistema

**Intento de solución:** Se intentó contenerizar el sistema con Docker pero el problema persistió — el token JWT no se mantenía entre reinicios de contenedor, posiblemente por inconsistencia del `JWT_SECRET` entre servicios dentro de Docker Compose.

**Estado:** Abierto. Pendiente de reproducir en un entorno controlado limpio.

---

### 🔴 ERR-002 — Creación de usuarios no funciona (regresión post-migración)

**Descripción:** Tras la migración del frontend de HTML/CSS/JS vanilla a React 18 en v1.1.0, la funcionalidad de crear nuevos usuarios desde el módulo de Gestión de Usuarios dejó de funcionar correctamente.

**Comportamiento observado:** El Boton de Agregar Usuario desapecio por Completo.

**Causa probable:** Falta de defincion en codigo React.

**Estado:** Parcialmente investigado. Se menciona una posible corrección en el commit de v1.2.0 pero no ha sido verificada de forma exhaustiva.

---

### 🟡 ERR-003 — API key de Groq expuesta en el bundle del cliente

**Descripción:** La API key de Groq configurada como variable de entorno de Vite (`VITE_GROQ_API_KEY`) queda embebida en el bundle JavaScript del frontend y es visible desde DevTools → Network o inspeccionando el bundle compilado.

**Impacto:** Cualquier usuario con acceso al frontend puede extraer la key y usarla fuera del sistema.

**Solución planificada (v1.3.0):** Mover las llamadas a Groq a un endpoint proxy en el gateway Node.js. El frontend llamaría a `POST /api/agent/query` y el gateway haría la llamada real a Groq con la key almacenada en el `.env` del servidor.

**Estado:** Abierto. Aceptado como deuda técnica para entorno académico/local.

---

### 🟡 ERR-004 — Historial del agente IA no persiste entre sesiones

**Descripción:** Al cerrar el panel del agente o recargar la página, el historial de conversación se pierde completamente.

**Causa:** El estado del componente `AgentBubble` vive en memoria React y no se persiste en ningún almacenamiento.

**Solución planificada (v1.3.0):** Guardar el historial en `localStorage` con un límite de los últimos 20 mensajes, asociado al `userId` del `AuthContext`.

**Estado:** Abierto. Bajo prioridad.

---

### 🟡 ERR-005 — Docker Compose: token JWT no se mantiene

**Descripción:** Al intentar contenerizar el sistema completo con Docker Compose, el login funciona pero las peticiones posteriores fallan con 401. El token generado por Java no es validado correctamente por el gateway.

**Causa probable:** El `JWT_SECRET` no es consistente entre el contenedor del gateway y el contenedor de Java, ya sea por variables de entorno mal inyectadas en el `docker-compose.yml` o por archivos `.env` no montados correctamente.

**Estado:** Abierto. Docker no es requisito del proyecto académico; se depriorizó.

---

## Decisiones técnicas documentadas

### DEC-001 — El frontend nunca llama directamente a Java ni Python

**Decisión:** Todo el tráfico del frontend pasa por el gateway Node.js, sin excepción (salvo `AgentBubble` en v1.2.0).

**Razón:** Centralizar autenticación JWT, CORS y logging en un solo punto. Permite cambiar la implementación interna de Java o Python sin tocar el frontend.

---

### DEC-002 — Python como microservicio real, no decorativo

**Decisión:** Python no está en el stack para cumplir un requisito de "usar N tecnologías". Es el único componente con capacidad estadística madura.

**Razón:** scikit-learn, pandas y numpy no tienen equivalente de facilidad y madurez en Java ni Node.js para análisis de series temporales. Su rol es exclusivo y no duplicado.

---

### DEC-003 — Migración de XAMPP a MySQL Community Server 8.0

**Decisión:** Se abandonó XAMPP como gestor de MySQL y se migró a MySQL Community Server 8.0 instalado de forma independiente.

**Razón:** XAMPP presentó inestabilidad recurrente durante el desarrollo — el servicio MySQL se detenía aleatoriamente, corrompía conexiones activas y generaba errores difíciles de diagnosticar. MySQL Community Server resultó significativamente más estable.

---

### DEC-004 — BCrypt: prefijo `$2b$` vs `$2a$`

**Decisión:** Se normalizó el hash de contraseñas para garantizar compatibilidad entre Python y Java.

**Razón:** Python genera hashes BCrypt con prefijo `$2b$` mientras que Spring Security espera `$2a$`. Esto causaba que las contraseñas creadas desde el seed o desde Python fueran rechazadas por Java. La solución fue estandarizar el prefijo en el seed y en la generación de contraseñas.

---

### DEC-005 — AgentBubble llama a Groq directamente desde el cliente

**Decisión:** En v1.2.0 el agente llama a la API de Groq directamente desde el navegador, sin pasar por el gateway.

**Razón:** Decisión de velocidad de implementación para la fase experimental. La arquitectura correcta (proxy en gateway) está planificada para v1.3.0 una vez el agente se estabilice.

**Deuda técnica generada:** API key expuesta en el bundle del cliente (ver ERR-003).

---

### DEC-006 — Groq como motor del agente en lugar de Gemini o OpenAI

**Decisión:** Se eligió Groq con el modelo `llama-3.3-70b-versatile` como motor del agente IA.

**Razón:** Groq ofrece un free tier real y generoso sin requerir tarjeta de crédito activa. Gemini API requiere billing activado en Google Cloud a pesar de tener "free tier". OpenAI no tiene free tier. Groq además ofrece latencia significativamente menor (~500ms) que los competidores.

---

## Funcionalidades planificadas

### v1.3.0 — Agente IA con datos reales

- [ ] Mover llamadas a Groq a un endpoint proxy en el gateway (`POST /api/agent/query`) — elimina ERR-003
- [ ] Darle al agente acceso de solo lectura al backend mediante tool use:
  - `get_dashboard_summary()` → métricas del día
  - `get_low_stock_products()` → productos en stock crítico
  - `get_sales_summary(days)` → resumen de ventas por período
  - `get_top_products()` → productos más vendidos
  - `get_prediction(product_id)` → predicción de demanda
- [ ] Persistencia del historial de conversación en `localStorage` por usuario — elimina ERR-004
- [ ] El agente puede responder con datos reales en lugar de respuestas orientativas

---

### v1.3.0 — Estabilidad y correcciones

- [ ] Investigar y resolver ERR-001 (arranque en otros PCs) — crear guía de diagnóstico paso a paso
- [ ] Verificar y cerrar ERR-002 (creación de usuarios post-migración React)
- [ ] Revisión completa del `start.bat` con validaciones de prerequisitos (Java, Python, Node, MySQL)

---

### v1.4.0 — Mejoras de inventario y ventas

- [ ] **Módulo de proveedores:** registro de proveedores por producto con contacto y lead time
- [ ] **Órdenes de compra:** generación de órdenes de reabastecimiento basadas en las recomendaciones del microservicio Python
- [ ] **Devoluciones de venta:** flujo completo de devolución que revierta stock e inventario
- [ ] **Exportar reportes a Excel/PDF:** el módulo de reportes actualmente solo muestra datos en pantalla
- [ ] **Filtros avanzados en ventas:** filtrar historial por vendedor, rango de fechas y estado

---

### v1.5.0 — Dashboard inteligente

- [ ] **Gráficos de tendencia:** visualización de ventas semanales/mensuales con Chart.js o Recharts
- [ ] **Comparativa de períodos:** ventas esta semana vs semana anterior, este mes vs mes anterior
- [ ] **Mapa de calor de ventas:** qué días y horas se vende más
- [ ] **Widget de predicción en dashboard:** mostrar los 3 productos con mayor demanda proyectada directamente en el dashboard sin ir al módulo de predicciones

---

### v2.0.0 — Multi-tenant y autenticación avanzada

- [ ] **Multi-tenancy:** soporte para múltiples negocios en la misma instancia, cada uno con su base de datos aislada
- [ ] **Refresh tokens:** actualmente el JWT expira y fuerza re-login; implementar refresh token silencioso
- [ ] **2FA opcional:** autenticación de dos factores para cuentas de administrador
- [ ] **Auditoría completa:** log de quién hizo qué y cuándo en todas las operaciones críticas
- [ ] **Roles personalizados:** en lugar de solo ADMIN/SELLER, permitir crear roles con permisos granulares

---

### Descartado / No planificado

| Feature | Razón |
|---------|-------|
| Aplicación móvil nativa | Fuera del alcance académico; el frontend React es responsive |
| Modelos LSTM / Prophet | Complejidad desproporcionada para el volumen de datos esperado |
| Integración con pasarelas de pago | No es un e-commerce; StockMind gestiona inventario, no cobra |
| WebSockets para tiempo real | Añade complejidad de infraestructura sin beneficio claro en el contexto actual |

---

*Última actualización: v1.2.0 — Mayo 2026*
