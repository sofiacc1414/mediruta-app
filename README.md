# MediRuta App

App Flutter de MediRuta (plataforma de domicilios de medicamentos) para los roles **Paciente** y **Domiciliario** — el panel Administrador/Root vive aparte, en `mediruta-web`.

La fuente única de verdad del proyecto (identidad visual, arquitectura, reglas de paridad entre superficies) es **[context.md](./context.md)** — cualquier duda de "cómo se hace acá" empieza ahí, no en este README.

## Stack

- **Flutter** + **Riverpod** (`flutter_riverpod`) para inyección de dependencias y estado.
- La App **nunca** habla directo con Supabase (ni datos ni auth) — todo pasa por `mediruta-api` vía `ApiClient` (`shared/core/network`). El JWT se guarda en `flutter_secure_storage`, nunca en `SharedPreferences` ni en memoria plana.
- `image_picker` (cámara/galería) + `file_picker` (selección de PDF) para fotos y documentos.
- `google_fonts` (Times New Roman MT Condensed / Poppins, paleta oficial de 5 colores — ver context.md Parte A).

## Arquitectura

Hexagonal por feature (`lib/features/<feature>/{domain,data,presentation}`), mismos nombres de clase que sus equivalentes en la API (`ObtenerPerfilUseCase`, etc.) para que se pueda trazar una historia de capa a capa y de repo a repo.

Carpetas de features: `usuarios` (HU-01/HU-02, implementado), `documentos`, `entregas`, `solicitudes` (scaffold para historias futuras, todavía sin implementar).

## Configuración local

```bash
flutter pub get
```

Apunta a la API local por defecto (`http://localhost:3000`). Para otro entorno:

```bash
flutter run -d chrome --web-port=5500 --dart-define=API_BASE_URL=http://localhost:3000
```

(Se usa el target Chrome con puerto fijo para desarrollo en Windows — el target Desktop requiere Developer Mode habilitado para symlinks de plugins, que el equipo optó por no habilitar. Con puerto fijo evitás tener que reconfigurar `CORS_ORIGINS` en la API cada vez que se relanza.)

## Tests

```bash
flutter analyze
flutter test
```

## Estado del proyecto

| Historia | Estado | Notas |
|---|---|---|
| **HU-01** — Gestión de acceso (onboarding, registro, login, cambio/recuperación de contraseña, logout) | ✅ Completa | Incluye selector de "Modo" post-login para cuentas con los dos roles (Paciente + Domiciliario) — la elección de rol nunca ocurre en el login, es una decisión de presentación después de autenticarse; con un solo rol no aparece selector, se resuelve solo. **Sesión única por usuario** (política nueva del lado de la API): loguearse en otro dispositivo cierra la sesión acá — no requirió ningún cambio en la App, el manejo de "el refresh token ya no sirve" (limpia tokens, fuerza login) ya existía para cualquier otro motivo de invalidación. Registrarse como Domiciliario ya no otorga Paciente automático — es un checkbox opcional en el registro; cualquier cuenta puede pedir después el rol que le falte desde "Mi perfil" ("Solicitar ser Paciente"/"Solicitar ser Domiciliario", ver detalle en HU-02). |
| **HU-02** — Administración del perfil de usuario | ✅ Completa | Pantalla "Mi perfil", accesible desde Inicio. Ver detalle abajo. |
| **HU-08** — Validación de domiciliarios | — | Es de Web (rol Administrador), no de App — completa en `mediruta-web`. |
| **HU-03** — Creación y gestión de solicitudes médicas | ✅ Completa | "Mis solicitudes", accesible desde Inicio (solo modo Paciente). Ver detalle abajo. |
| **HU-04** — OCR de fórmula médica | 🔜 Próxima | — |
| **HU-05** — Gestión de documentos de la solicitud | 🔜 Próxima | — |

### HU-02 — qué incluye

- Secciones de perfil condicionales por rol: datos comunes (**correo** de solo lectura, nombre/teléfono editables) siempre; Paciente (dirección de entrega, fecha de nacimiento, foto de cédula) y/o Domiciliario (dirección de residencia, vehículo, cédula/licencia/SOAT/tecnomecánica) según el **"Modo" activo** elegido en Inicio — una cuenta con los dos roles no ve ambas tarjetas mezcladas.
- El correo se muestra pero no se edita acá (no hay esa funcionalidad) — sale de la sesión autenticada (`authSessionProvider`), no de `GET /perfil` (esa respuesta no lo trae).
- **"Cambiar contraseña"** vive en "Mi perfil" (sección "Datos básicos"), no en Inicio — se movió ahí por ser una acción de cuenta, junto al resto de los datos de la cuenta.
- Foto de perfil (avatar) con subida/reemplazo desde la propia pantalla.
- Miniaturas reales de los documentos ya subidos (imagen o ícono de PDF), no solo un check — usa las URLs firmadas que devuelve la API.
- Subida de documentos con 3 orígenes: cámara, galería o **elegir PDF** del dispositivo (para SOAT/tecnomecánica que ya existen como PDF, sin forzar a fotografiarlos).
- Desactivación de cuenta con confirmación, cierra la sesión localmente.
- **"Otro rol"**: si a la cuenta le falta el rol Paciente y/o Domiciliario, aparece un botón por cada uno que falte ("Solicitar ser Paciente"/"Solicitar ser Domiciliario"). Paciente se agrega al instante; Domiciliario queda `pendiente_validacion` — de ahí en más es exactamente el mismo perfil a completar (vehículo, documentos) que un Domiciliario recién registrado, pero **con dirección y foto de cédula ya precargadas** (la API las reusa del otro perfil) — solo faltan los datos que de verdad son nuevos. Después de agregar un rol se refresca tanto la sesión (`authSessionProvider.sesionIniciada`, los roles no viven en el JWT) como el perfil (para que esos datos precargados se vean sin un pull-to-refresh manual) — no navega directo al rol nuevo, elegir modo sigue siendo una acción explícita en Inicio.

### HU-03 — qué incluye

Reworkeada tras revisión en vivo de la primera versión (una fórmula real trae varios
medicamentos, y la receta se sube como foto, no se tipea):

- **"Nueva solicitud"**: mientras el paciente completa el formulario, **nada viaja a la API** — se guarda solo en el dispositivo (`shared_preferences`) en cada cambio, para que sobreviva aunque cierren la app de golpe. Recién se crea en la API cuando completa todo y envía, o cuando intenta salir y confirma "guardar para continuar después" (si dice que no, se descarta sin haber tocado el backend). La foto de receta elegida NO se guarda en ese borrador local (evita codificar imágenes en base64 en `shared_preferences`) — se sube recién cuando la solicitud se persiste de verdad.
- Misma pantalla sirve para **editar** una solicitud ya creada en Borrador (`solicitudId` no nulo) — ahí sí habla con la API directo, sin el paso de borrador local (ya existe del lado del servidor).
- **Varios medicamentos por solicitud**: sección repetible, "Agregar medicamento" suma una línea, cada una con botón "Quitar" (deshabilitado si es la única).
- **Receta = foto**, no texto — mismo selector cámara/galería/PDF que los documentos de HU-02, más el campo de **fecha de vencimiento** (el único dato tipeado que queda; corregido desde "fecha de expedición" — esa no servía para detectar una receta vencida, era el dato equivocado).
- **Antes de poder crear una solicitud**, si el perfil del paciente no tiene foto de cédula cargada (HU-02), un diálogo lo manda directo a "Mi perfil" — ni siquiera entra al formulario. La cédula del pedido en sí es una referencia viva al perfil, nunca una subida aparte.
- **Dos direcciones**: dirección de la farmacia (dónde el domiciliario retira el medicamento, se escribe a mano) y dirección de entrega (dónde se lo lleva al paciente, precargada del perfil HU-02 pero editable) — puntos distintos, no un duplicado.
- "Mis solicitudes" (lista) → detalle con los medicamentos, miniatura de receta, miniatura de cédula (de solo lectura) e historial de estados → Editar/Enviar/Cancelar según el estado actual.
- **Miniatura de receta/cédula tocable**: una imagen de 44px no alcanza para leer una fórmula médica — tocarla abre `app_image_viewer.dart` (visor a pantalla completa con zoom, sin paquete nuevo, usa `InteractiveViewer` nativo), tanto para la foto recién elegida (todavía no subida) como para la ya subida al servidor.
- "Enviar solicitud" se deshabilita solo si falta algún requisito, mostrando cuáles — mismo cálculo que hace la API (`app.enviar_solicitud`), incluyendo **receta vencida** (`recetaFechaVencimiento` ya pasada), para no depender de chocar con el error para avisar.
- **Código de pedido**: se genera recién al enviar (`MR-000001`, ...) — antes no existía, la solicitud enviada solo tenía su uuid interno. Al enviar aparece un diálogo con el código (pantalla de creación) o un snackbar (pantalla de detalle); de ahí en más reemplaza a "Solicitud del &lt;fecha&gt;" como título en la lista y en el detalle.

64/64 tests pasando.

### Notas técnicas para quien retome esto

- El "Modo" activo (Paciente/Domiciliario) vive en `modoActivoProvider` (`auth_session_provider.dart`), compartido entre pantallas — si agregás una pantalla nueva que dependa del rol activo, léelo de ahí, no reinventes estado local como se hacía antes en `home_screen.dart`.
- `SharedPreferences` se resuelve una sola vez en `main()` (es async) y se inyecta vía `sharedPreferencesProvider.overrideWithValue(...)` — cualquier provider que lo necesite lo lee de ahí, nunca llama `SharedPreferences.getInstance()` por su cuenta.
- `ApiClient.onSesionExpirada` (renovación automática de sesión ante un 401) se conecta desde `apiClientRefreshWiringProvider`, un provider intermedio — **no** lo muevas de vuelta a `apiClientProvider` directamente, causa un `CircularDependencyError` real de Riverpod (el comentario en `usuario_providers.dart` explica por qué).
