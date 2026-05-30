# Kotorra app

Aplicación móvil oficial de Kotorra desarrollada en Flutter.

## Descripción

Kotorra es una plataforma colaborativa para estudiantes universitarios que permite compartir, descubrir y organizar recursos académicos como:

* Apuntes
* Guías de estudio
* Trabajos prácticos
* Ejercicios resueltos
* Tesis
* Material multimedia

Esta aplicación móvil consume la API desarrollada en FastAPI y busca ofrecer una experiencia rápida, moderna y accesible desde dispositivos Android e iOS.

---

## Características previstas

### Autenticación

* Registro de usuarios
* Inicio de sesión
* Recuperación de contraseña
* Gestión segura de tokens JWT

### Gestión académica

* Exploración de documentos
* Búsqueda avanzada
* Descarga de archivos

### Comunidad

* Perfil de usuario
* Valoraciones
* Comentarios

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
git clone https://github.com/usuario/kotorra-mobile.git
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

Crear el archivo:

```text
.env
```

Ejemplo:

```env
API_BASE_URL=http://localhost:8000/api/v1
```

Para producción:

```env
API_BASE_URL=https://api.kotorra.com/api/v1
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

La aplicación se comunica exclusivamente mediante la API REST.

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

## Construcción

Android APK:

```bash
flutter build apk
```

## Roadmap

### MVP

* Registro e inicio de sesión
* Perfil de usuario
* Navegación de documentos
* Descarga de recursos
* Búsqueda básica

### Versión 1.0

* Comentarios
* Valoraciones
* Favoritos
* Historial de actividad
* Notificaciones push

### Futuro

* Lectura integrada de PDFs
* Sincronización offline

---

## Licencia

Proyecto desarrollado como parte del trabajo final de la carrera de Programador Universitario.

© Kotorra

