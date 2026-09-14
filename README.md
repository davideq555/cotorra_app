# Cotorra app

[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Backend](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Auth](https://img.shields.io/badge/Auth-JWT-000000?logo=jsonwebtokens&logoColor=white)](#)
[![Estado](https://img.shields.io/badge/Estado-En%20desarrollo-yellow)](#)

Aplicación móvil oficial de Cotorra desarrollada en Flutter.

> **Proyecto para la UNSA.** Este desarrollo se realiza como trabajo final de la carrera de **Tecnico Universitario en Programacion** de la **Universidad Nacional de Salta (UNSa)**.

## Descripción

Cotorra es una plataforma colaborativa para estudiantes universitarios que permite compartir, descubrir y organizar recursos académicos como:

* Apuntes
* Guías de estudio
* Trabajos prácticos
* Ejercicios resueltos
* Tesis
* Material multimedia

Esta aplicación móvil consume la API desarrollada en FastAPI y busca ofrecer una experiencia rápida, moderna y accesible desde dispositivos Android.

---

## Sobre el proyecto

Este repositorio corresponde al **cliente móvil** de Cotorra, desarrollado en el marco del **trabajo final de la carrera de Programador Universitario de la Universidad Nacional de Salta (UNSA)**.

* **Institución:** Universidad Nacional de Salta (UNSA)
* **Carrera:** Tecnico Universitario en Programacion
* **Tipo de proyecto:** Trabajo final
* **Alcance de este repositorio:** aplicación móvil (cliente). El backend es un servicio FastAPI independiente.
* **Sitio de la universidad:** [unsa.edu.ar](https://www.unsa.edu.ar)

---

## Características previstas

### Autenticación

* Registro de usuarios
* Inicio de sesión
* Inicio de sesión con Google (OAuth)
* Recuperación de contraseña
* Gestión segura de tokens JWT (con refresh token)

### Gestión académica

* Exploración de documentos
* Búsqueda avanzada
* Descarga de archivos (Proximamente)
* Lectura integrada de PDFs e imágenes

### Comunidad

* Perfil de usuario
* Edición y eliminación de documentos propios
* Valoraciones (Proximamente)
* Comentarios (Proximamente)

### Experiencia móvil

* Modo claro y oscuro
* Diseño responsive
* Caché local
* Soporte offline parcial

---

## Configuración del entorno

### Requisitos

* Flutter SDK
* Dart SDK
* Android Studio o VS Code
* Android SDK

Verificar instalación:

```bash
flutter doctor
```

---

## Instalación

Clonar el repositorio:

```bash
git clone https://github.com/davideq555/cotorra_app.git
```

Ingresar al proyecto:

```bash
cd cotorra_app
```

Instalar dependencias:

```bash
flutter pub get
```

---

## Variables de entorno

Crear el archivo a partir de `.env.example`:

```bash
cp .env.example .env
```

El archivo `.env` es obligatorio: la app lo carga al iniciar. **No se sube al repositorio** (está en `.gitignore`).

Ejemplo para desarrollo local:

```env
API_BASE_URL=http://localhost:8000/api/v1
```
---

## Ejecutar en desarrollo

```bash
flutter run
```

Ejecutar en un dispositivo específico:

```bash
flutter devices

flutter run -d <device_id>
```

---

## Integración con Backend

Backend principal:

* FastAPI
* PostgreSQL
* JWT Authentication

La aplicación se comunica exclusivamente mediante la API REST. El contrato de referencia de la API está en [`openapi.json`](openapi.json).

> Nota: `openapi.json` es solo un contrato de referencia. No hay generación de código; los modelos y `ApiService` se actualizan a mano cuando cambia el backend.

---

## Calidad de código

Análisis estático:

```bash
flutter analyze
```

Formateo:

```bash
dart format .
```

---

## Tests

Tests unitarios (no requieren backend):

```bash
flutter test test/services/api_service_test.dart
```

Tests de integración (requieren un backend en ejecución y un usuario de prueba; realizan escrituras reales):

```bash
flutter test test/services/api_service_integration_test.dart
```

---

## Construcción

Android APK:

```bash
flutter build apk
```

---

## Roadmap

### MVP

* Registro e inicio de sesión
* Perfil de usuario
* Navegación de documentos
* Favoritos de recursos
* Búsqueda avanzada
* Lectura integrada de PDFs, imagenes

### Versión 1.0

* Comentarios
* Valoraciones
* Editar perfil y documentos
* Historial de actividad
* Sincronización offline

---

## Licencia

Proyecto desarrollado como parte del trabajo final de la carrera de la **Universidad Nacional de Salta (UNSA)**.

© Cotorra — Todos los derechos reservados.
