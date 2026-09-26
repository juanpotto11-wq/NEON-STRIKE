# Compilar NEON STRIKE V3 a APK gratis

1. Crea un repositorio nuevo en GitHub.
2. Sube TODO el contenido de esta carpeta (incluido `.github`).
3. En GitHub abre **Actions**.
4. Selecciona **Build NEON STRIKE APK**.
5. Pulsa **Run workflow**.
6. Cuando termine, abre el workflow y descarga el artifact **NEON_STRIKE-Android**.
7. Dentro estará `NEON_STRIKE.apk`.

Notas:
- El workflow compila una APK de prueba/producción sin firma de Play Store.
- Para publicar en Google Play necesitarás una clave de firma propia y configurar el keystore.
- Si la imagen de Godot del workflow cambia o deja de existir, se puede sustituir por otra imagen compatible con Godot 4.x.
