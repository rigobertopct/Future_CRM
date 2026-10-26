# Future CRM

App Flutter para gestionar leads y contactos comerciales. Hoy solo el módulo **Leads** está implementado; el resto de secciones muestran "próximamente".

## Estructura (`lib/`)

| Carpeta | Contenido |
|---|---|
| `app/` | Estado global (`CrmController`), navegación y `CrmScope` |
| `core/api/` | `CrmClient` (HTTP + errores) y `CrmSession` |
| `core/theme/` | Colores, tema y tipografía |
| `animations/` | Widgets de animación reutilizables |
| `features/leads/` | Modelo, API, store, página, lista, diálogos y widgets |
| `features/shell/` | Layout con sidebar y barra superior |

Flujo de datos: `LeadsApi` (HTTP o memoria) → `LeadsStore` (`ChangeNotifier`) → widgets vía `ListenableBuilder`.

## Ejecutar

```bash
flutter pub get
flutter run
```

La sesión de desarrollo viene por defecto; para usar otra:

```bash
flutter run --dart-define=CRM_TOKEN=... --dart-define=CRM_OWNER=... --dart-define=CRM_ENDPOINT=...
```

## Calidad

```bash
flutter analyze
flutter test
```

Los tests usan `MemoryLeadsApi` y `sample_leads.dart` (en `test/`) para no depender del servidor.
