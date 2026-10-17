# Vigilo — App móvil

Cliente Flutter de **Vigilo**: reporte de incidentes urbanos sobre un mapa y el marketplace de reciclaje (publicar material, reclamarlo, pesarlo, confirmar el recojo, acumular y canjear puntos). Puede correr contra el backend real o en un **modo demo** 100% local, sin backend ni Firebase — ver más abajo.

## Stack

- Flutter + Dart 3, `flutter_riverpod` para estado/DI.
- `dio` para HTTP, `flutter_secure_storage` para la sesión (JWT access + refresh).
- `flutter_map` + OpenStreetMap para el mapa, `geolocator` para ubicación.
- `firebase_core` + `firebase_messaging` para notificaciones push (solo en modo online).
- `google_fonts` (Hanken Grotesk / Inter / JetBrains Mono) — ver `DESIGN.md` en la raíz del repo para el sistema de diseño.

## Estructura del proyecto

```
lib/
├── main.dart                      # Bootstrap: Firebase.initializeApp() (si no es modo demo), tema, ProviderScope
├── core/
│   ├── config/app_config.dart     # apiBaseUrl y demoMode — ver "Modo online vs. modo demo" abajo
│   ├── network/                   # ApiClient (Dio + refresh automático de sesión), ApiException
│   ├── storage/                   # SecureSessionStorage (JWT en flutter_secure_storage)
│   ├── push/                      # PushNotificationService (envoltorio sobre FirebaseMessaging)
│   └── logging/app_logger.dart    # Logger liviano por módulo (dart:developer), usado en red/auth/push
├── domain/
│   ├── entities/                  # Modelos de dominio (Incident, User, RecyclingListing, RecyclingPickup, ...)
│   └── repositories/              # Contratos (AuthRepository, RecyclingRepository, ...) — cada uno tiene
│                                     una implementación Remote* y una Demo*, ver abajo
├── data/
│   ├── datasources/remote/        # Llamadas HTTP crudas (una por módulo del backend)
│   ├── repositories/              # Remote*RepositoryImpl (contra el backend) y Demo*RepositoryImpl (en memoria)
│   ├── demo/demo_state.dart       # Estado y datos semilla del modo demo (único singleton en memoria)
│   └── models/                    # Modelos del mock local histórico (usuarios/incidentes/productos semilla)
├── presentation/
│   ├── providers/providers.dart   # Wiring central de Riverpod: elige Remote o Demo según AppConfig.demoMode
│   └── screens/                   # Pantallas ya migradas al sistema de diseño actual (dashboard, mapa,
│                                     reciclaje, perfil, tienda, alertas)
├── screens/                       # Pantallas aún no migradas a presentation/screens (login, registro,
│                                     puntos, KPIs, impacto, colecciones) — funcionales, pendientes de mover
├── theme/                         # AppColors, AppTheme, AppTypography, AppIcons — tokens del sistema de diseño
└── widgets/                       # Widgets compartidos (MainAppBar, tarjetas de alerta, etc.)
```

## Requisitos previos

- Flutter SDK (ver `environment.sdk` en `pubspec.yaml`).
- Para correr en un emulador/dispositivo Android: Android Studio + un AVD, o un dispositivo físico con depuración USB.
- **Modo online:** el backend corriendo — ver [`../backend/README.md`](../backend/README.md).
- **Modo demo:** nada más que Flutter. No necesita backend, Firebase, ni conexión.

```bash
flutter pub get
```

## Modo online vs. modo demo

La app tiene una sola bandera que decide todo: `AppConfig.demoMode` (`lib/core/config/app_config.dart`). Por defecto es `false` (modo online).

### Modo online (por defecto)

Habla con el backend real vía `AppConfig.apiBaseUrl` (por defecto `http://10.0.2.2:3000/api/v1`, el alias que usa el **emulador de Android** para llegar al `localhost` de la máquina host).

```bash
flutter run
```

Para un dispositivo físico o un backend remoto, sobreescribe la URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000/api/v1
```

En este modo, login/registro crean sesión real contra el backend, las notificaciones push se registran de verdad (si `firebase-sa.json` está configurado en el backend), y todo lo que se publica/reporta persiste en Postgres.

### Modo demo (presentaciones sin backend)

Reemplaza los 8 repositorios (auth, incidentes, reciclaje, tienda, puntos, analytics, media, notificaciones) por implementaciones 100% locales (`Demo*RepositoryImpl`, ver `lib/data/repositories/` y `lib/data/demo/demo_state.dart`). No se inicializa Firebase ni se hace ninguna llamada de red.

```bash
flutter run --dart-define=DEMO_MODE=true
```

(Para generar un APK de demo sin recordar el flag cada vez, también se puede cambiar el `defaultValue` a `true` directamente en `app_config.dart` antes de compilar.)

**Cuentas semilla** (la pantalla de login muestra un botón de acceso rápido cuando el modo demo está activo):

| Cuenta | Contraseña | Para qué sirve |
|---|---|---|
| `ana@gmail.com` | `12345678` | Cuenta principal de demo: ya tiene incidentes reportados/validados/resueltos, una publicación de reciclaje completada y confirmada, historial de puntos (+50 bono, +25 recojo, -30 canje) y un canje ya cumplido. Puede activar el rol de reciclador desde su perfil para reclamar las publicaciones de Carlos. |
| `carlos@gmail.com` | `12345678` | Segunda cuenta ciudadana — tiene sus propias publicaciones pendientes (cartón, vidrio) para que Ana las reclame, y es quien debe confirmar el recojo una vez que Ana lo complete (en "Mis Publicaciones"). |
| `roberto@seguridadtotal.com`, `patricia@ecolimpia.com`, etc. | `12345678` | Roles de empresa (seguridad/limpieza) — ver `lib/data/datasources/local_json_datasource.dart` para la lista completa. |

Los datos de usuarios/incidentes/tienda persisten en un archivo local del dispositivo entre reinicios de la app (mismo mecanismo que el mock previo a la integración con el backend); el marketplace de reciclaje, el ledger de puntos y las notificaciones viven solo en memoria y se reinician en cada arranque — a propósito, para que una demo siempre empiece desde un estado conocido.

**Flujo de reciclaje de punta a punta en modo demo:**
1. Entra como `ana@gmail.com`, activa el rol de reciclador en su perfil.
2. "Mis Recolecciones" → reserva una de las publicaciones de Carlos (cartón o vidrio).
3. Abre el recojo reservado → marca en camino → marca llegada → registra el pesaje (peso real, método de pago, voucher opcional).
4. Cierra sesión, entra como `carlos@gmail.com` → "Mis Publicaciones" → la publicación completada → confirma (acredita los puntos) o disputa.

## Testing / verificación

```bash
flutter analyze              # Análisis estático
flutter build apk --debug    # Compilación de verificación (modo online)
flutter build apk --debug --dart-define=DEMO_MODE=true   # Idem, modo demo
```

No hay suite de widget/integration tests todavía — la verificación de flujos se ha hecho mediante `flutter analyze` + compilación + revisión manual de cada pantalla contra el backend real.

## Firebase (solo modo online)

El proyecto Firebase (`vigilo-c1484`, paquete `com.vigilo.app.bo`) ya está configurado en `android/app/google-services.json` y el plugin de Gradle ya está aplicado. Si Firebase no logra inicializarse por cualquier motivo (p. ej. un emulador sin Google Play Services), `main.dart` lo tolera y la app sigue funcionando sin push — nunca bloquea el arranque.

## Documentación relacionada

- [`../DESIGN.md`](../DESIGN.md) — sistema de diseño (colores, tipografía, radios).
- [`../docs/`](../docs/README.md) — reglas de negocio, flujos y decisiones del proyecto completo.
- [`../backend/README.md`](../backend/README.md) — cómo levantar el backend para el modo online.
