# Proyecto Final FoodMaps

Este repositorio contiene el **backend** y **frontend** del proyecto.

- `backend/` → API en Laravel
- `frontend/` → App móvil en Flutter (Android Studio, Dart)

---

## Requisitos Previos

### Backend
- PHP >= 8.2
- Composer
- MySQL
- **Entorno recomendado en Windows:** Laragon o XAMPP

### Frontend
- Flutter SDK con version de dart(3.8.1)
- Android Studio 2024 >=
- Emulador de Android o dispositivo físico

## Instalación

### 1. Backend (Laravel API)

1. Ir a la carpeta del backend:
    ```bash
    cd backend
2. Instalar dependencias:
    composer install
    Importante: (Se necesita la extension de php: **sodium**)
3. Copiar archivo de ejemplo de variables de entorno:
    cp .env.example .env
4. Configurar .env con tus datos de base de datos, puerto y demás parámetros:
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=nombre_base_datos
    DB_USERNAME=usuario
    DB_PASSWORD=contraseña

    R
5. Generar clave de aplicación:
    php artisan key:generate
6. Ejecutar migraciones:
    php artisan migrate
7. Iniciar servidor de desarrollo:
    php artisan serve
8. Instalar laravel reverb
    php artisan install:broadcasting
    Importante: .env() -> REVERB_PORT=9000
9. Correr reverb
    php artisan reverb:start --port=9000

### 2. Frontend
1. Ir a la carpeta del frontend:
    cd frontend
2. Instalar dependencias de Flutter:
    flutter pub get
3. Configurar la URL base de la API en tu app (ejemplo en config.dart):
    const String apiBaseUrl = "http://127.0.0.1:8000";
4. Instalacion de jdk (java) version: 17.0.16
5. Conectar tu emulador o dispositivo Android y ejecutar:
    flutter run
6. Opcional: abrir el proyecto en Android Studio para trabajar con la interfaz y debug.

### Notas Importantes

Asegúrate de que el backend esté corriendo antes de abrir la app en Flutter para que la API funcione correctamente.