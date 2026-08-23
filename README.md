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
| **HU-01** — Gestión de acceso (onboarding, registro, login, cambio/recuperación de contraseña, logout) | ✅ Completa | Incluye selector de "Modo" post-login para cuentas con los dos roles (Paciente + Domiciliario) — la elección de rol nunca ocurre en el login, es una decisión de presentación después de autenticarse. |
| **HU-02** — Administración del perfil de usuario | ✅ Completa | Pantalla "Mi perfil", accesible desde Inicio. Ver detalle abajo. |
| **HU-08** — Validación de domiciliarios | — | Es de Web (rol Administrador), no de App — completa en `mediruta-web`. |
| **HU-03** — Creación y gestión de solicitudes médicas | ✅ Completa | "Mis solicitudes", accesible desde Inicio (solo modo Paciente). Ver detalle abajo. |
| **HU-04** — OCR de fórmula médica | 🔜 Próxima | — |
| **HU-05** — Gestión de documentos de la solicitud | 🔜 Próxima | — |

### HU-02 — qué incluye

- Secciones de perfil condicionales por rol: datos comunes (nombre/teléfono) siempre; Paciente (dirección de entrega, fecha de nacimiento, foto de cédula) y/o Domiciliario (dirección de residencia, vehículo, cédula/licencia/SOAT/tecnomecánica) según el **"Modo" activo** elegido en Inicio — una cuenta con los dos roles no ve ambas tarjetas mezcladas.
- Foto de perfil (avatar) con subida/reemplazo desde la propia pantalla.
- Miniaturas reales de los documentos ya subidos (imagen o ícono de PDF), no solo un check — usa las URLs firmadas que devuelve la API.
- Subida de documentos con 3 orígenes: cámara, galería o **elegir PDF** del dispositivo (para SOAT/tecnomecánica que ya existen como PDF, sin forzar a fotografiarlos).
- Desactivación de cuenta con confirmación, cierra la sesión localmente.

### HU-03 — qué incluye

- **"Nueva solicitud"**: mientras el paciente completa el formulario (medicamento + receta médica + dirección de entrega), **nada viaja a la API** — se guarda solo en el dispositivo (`shared_preferences`) en cada cambio, para que sobreviva aunque cierren la app de golpe. Recién se crea en la API cuando completa todo y envía, o cuando intenta salir y confirma "guardar para continuar después" (si dice que no, se descarta sin haber tocado el backend).
- Misma pantalla sirve para **editar** una solicitud ya creada en Borrador (`solicitudId` no nulo) — ahí sí habla con la API directo, sin el paso de borrador local (ya existe del lado del servidor).
- Campos de medicamento y receta médica definidos investigando qué exige una fórmula válida en Colombia — la foto/escaneo de la receta es HU-05, el OCR es HU-04, acá los datos se tipean.
- Dirección de entrega precargada del perfil (HU-02), editable por solicitud.
- "Mis solicitudes" (lista) → detalle con historial de estados → Editar/Enviar/Cancelar según el estado actual.
- "Enviar solicitud" se deshabilita solo si falta algún campo obligatorio, mostrando cuáles — mismo cálculo que hace la API (`app.enviar_solicitud`), para no depender de chocar con el error para avisar.

52/52 tests pasando.

### Notas técnicas para quien retome esto

- El "Modo" activo (Paciente/Domiciliario) vive en `modoActivoProvider` (`auth_session_provider.dart`), compartido entre pantallas — si agregás una pantalla nueva que dependa del rol activo, léelo de ahí, no reinventes estado local como se hacía antes en `home_screen.dart`.
- `SharedPreferences` se resuelve una sola vez en `main()` (es async) y se inyecta vía `sharedPreferencesProvider.overrideWithValue(...)` — cualquier provider que lo necesite lo lee de ahí, nunca llama `SharedPreferences.getInstance()` por su cuenta.
- `ApiClient.onSesionExpirada` (renovación automática de sesión ante un 401) se conecta desde `apiClientRefreshWiringProvider`, un provider intermedio — **no** lo muevas de vuelta a `apiClientProvider` directamente, causa un `CircularDependencyError` real de Riverpod (el comentario en `usuario_providers.dart` explica por qué).
