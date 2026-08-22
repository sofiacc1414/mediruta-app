# MediRuta App

App móvil de MediRuta (Paciente y Domiciliario) — Flutter + Riverpod.

**Antes de cualquier tarea de diseño o código, lee y respeta el contexto técnico completo del proyecto:**

@context.md

Ese documento es la fuente única de verdad — sistema visual (Parte A: paleta, tipografía) y arquitectura/backend/BD/flujo de trabajo (Parte B, sección 11 es la específica de Flutter). Si una instrucción puntual contradice ese documento, el documento tiene prioridad, salvo que el equipo decida modificarlo explícitamente.

## Reglas operativas rápidas para este repo

- Paleta y tipografía oficiales únicamente (Parte A, secciones 3-6) — usa `lib/shared/core/theme/app_colors.dart` y `app_theme.dart`, no definas colores nuevos en un widget.
- Estructura por entidad en `lib/features/` (usuarios, solicitudes, documentos, entregas), cada una con `domain/`, `data/`, `presentation/` (sección 11).
- Esta app es la que usan los roles **Paciente y Domiciliario** — antes de construir una pantalla, confirma en el backlog que la historia corresponde a alguno de esos roles.
- Un `usecase` por funcionalidad, nombrado igual que su contraparte en la API (sección 5 y 11) — la capa `presentation` nunca llama directo a `datasources`.
- **La app nunca habla con Supabase directamente**, ni siquiera para login — todo pasa por `lib/shared/core/network/api_client.dart` hacia la API. El JWT se guarda con `flutter_secure_storage` (sección 4.1).
- Ninguna funcionalidad se implementa sin plan previo — usa el modo plan de Claude Code antes de escribir código (sección 12).
- Si una pantalla nueva corresponde a algo ya construido en la API, revisa la regla de paridad (sección 10) antes de darla por terminada.
