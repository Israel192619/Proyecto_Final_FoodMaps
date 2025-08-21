# Usa una imagen base de Debian
FROM debian:bullseye-slim

# Establecer variables de entorno para Android SDK y Flutter
ENV ANDROID_HOME=/usr/local/android
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:/usr/local/flutter/bin:$PATH"

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    xz-utils \
    git \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && apt-get clean

# Descargar y configurar Flutter SDK
RUN curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz \
    && tar xf flutter_linux_3.24.5-stable.tar.xz \
    && mv flutter /usr/local/flutter \
    && rm flutter_linux_3.24.5-stable.tar.xz

# Configurar Flutter
RUN git config --global --add safe.directory /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:$PATH"
RUN flutter doctor -v

# Configurar directorio de trabajo
WORKDIR /app

# Copiar la aplicación Flutter al contenedor
COPY . .

# Ejecutar 'flutter pub get' para instalar las dependencias
RUN flutter pub get

# Descargar y configurar Android SDK Command Line Tools
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip \
    && mkdir -p /usr/local/android/cmdline-tools \
    && unzip cmdline-tools.zip -d /usr/local/android/cmdline-tools \
    && mkdir -p /usr/local/android/cmdline-tools/latest \
    && mv /usr/local/android/cmdline-tools/cmdline-tools /usr/local/android/cmdline-tools/latest \
    && rm cmdline-tools.zip

# Aceptar las licencias de Android SDK
RUN yes | /usr/local/android/cmdline-tools/latest/bin/sdkmanager --licenses
# Instalar las herramientas necesarias de Android SDK
RUN /usr/local/android/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_HOME} "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# Verificar la instalación
RUN flutter doctor -v

# Comando por defecto
CMD ["flutter", "run"]