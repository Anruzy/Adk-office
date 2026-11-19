# Hoja de ruta

## Fase 1: base de compilación (actual)

- [x] Estructura del proyecto sobre el monorepo de Collabora Office
- [x] Scripts de compilación reproducibles (commits anotados en `FUENTES.txt`)
- [x] GitHub Actions con ccache, artefacto y Releases
- [x] Identidad propia: nombre, paquete, ícono y encabezado
- [x] Copias temporales de documentos en la tarjeta SD (con interruptor)
- [x] App movible a SD adoptada (`installLocation="auto"`)
- [ ] Primer APK compilado y probado en un celular real

## Fase 2: experiencia en el celular

- [ ] Pantalla de inicio con "Nuevo documento / hoja / presentación"
- [ ] Carpeta predeterminada para documentos nuevos (interna o SD)
- [ ] Revisar textos que aún digan "Collabora" en la interfaz web
- [ ] Tema propio (colores) en la interfaz de edición
- [ ] Diccionarios de ortografía en español incluidos

## Fase 3: distribución

- [ ] APK firmado de versión
- [ ] Builds para `armeabi-v7a` (celulares de 32 bits)
- [ ] Publicación en F-Droid (repositorio propio o principal)
