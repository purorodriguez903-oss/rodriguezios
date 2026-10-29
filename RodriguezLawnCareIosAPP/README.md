# Rodriguez LawnCare iOS App 🌿📱

Aplicación nativa para iPhone / iPad desarrollada en SwiftUI para la administración integral de **Rodriguez LawnCare**.

---

## 🚀 Funcionalidades Principales

1. **📅 Citas & Clientes en Tiempo Real**:
   - Visualiza al instante las citas y cotizaciones solicitadas en tu página web.
   - Botón directo para abrir chat de **WhatsApp** con saludo personalizado para el cliente.
   - Botón de llamada directa telefónica.
   - Apertura de dirección en **Apple Maps** para navegación GPS.
   - Cambio de estado: *Pendiente*, *Contactado*, *Cotizado*, *Confirmado*, *Completado*.
   - Agregar nuevas citas manualmente con selector de servicios y notas.

2. **💵 Dar Estimados & Calculadora de Precios**:
   - Calculadora instantánea basada en el tamaño del jardín (< 5,000 sq ft, 5,000 - 10,000 sq ft, 10,000 - 15,000 sq ft, Acre).
   - Ajustes por altura de césped y descuentos por frecuencia (Semanal -10%, Quincenal -5%).
   - Servicios adicionales: Poda de arbustos, Instalación de Mulch, Poda de ramas, Limpieza general y Bordes de aceras.
   - Generación de cotización formal con 1 toque:
     - Enviar directo por **WhatsApp** al cliente.
     - Enviar por **SMS**.
     - Copiar al portapapeles.
     - Guardar automáticamente como cita en el sistema.

3. **📸 Galería Web en Vivo**:
   - Administra el portafolio de fotos que se ven en la web (`gallery.json`).
   - Sube nuevas fotos de trabajos realizados con título y categoría.
   - Elimina fotos antiguas con 1 toque.

4. **🌐 Web & Servidor**:
   - Monitoreo del estado del servidor y bot de Discord.
   - Configuración de la URL de la API de producción.
   - Enlace directo para abrir la página web oficial.

---

## 🛠️ Compilación Automática del Archivo `.ipa` en GitHub Actions

El repositorio cuenta con un flujo automatizado de CI/CD en `.github/workflows/ios-build.yml`:

1. Al hacer `git push` a la rama `main` o al activar el workflow manualmente en GitHub (**Actions** -> **Build Rodriguez LawnCare for iOS** -> **Run workflow**).
2. GitHub compila el proyecto en un runner macOS (`macos-15`) utilizando `xcodebuild`.
3. Empaqueta la app en formato `.ipa` sin firmar (`RodriguezLawnCare-unsigned.ipa`).
4. Descarga el archivo generado desde la sección **Artifacts** de la ejecución.

---

## 📲 Instalación en tu iPhone

El IPA se compila sin firma para que puedas firmarlo con tu propio certificado o método preferido:

- **ESign**: Importa el `.ipa` descargado, firma con tu certificado y presiona *Instalar*.
- **TrollStore**: Si tienes TrollStore, puedes instalar el `.ipa` directamente con soporte permanente.
- **AltStore / Sideloadly / Scarlet**: Conecta tu dispositivo o sube el IPA con tu Apple ID.
