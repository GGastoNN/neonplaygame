# Neon Apex: Open Roads

Prototipo jugable de carreras arcade para Android creado con **Godot 4.3**.

## Proyecto corregido para GitHub Actions

Esta versión deja el proyecto Godot directamente en la raíz del repositorio. **No subas el proyecto dentro de otro ZIP**: GitHub Actions necesita encontrar `project.godot`, `export_presets.cfg`, `scenes/` y `scripts/` en la raíz.

La compilación Android usa:

- Godot 4.3 estable.
- OpenJDK 17.
- Android SDK Platform 34.
- Android Build Tools 34.0.0.
- Debug keystore generado automáticamente en cada ejecución.
- Exportación `--export-debug`, evitando exigir una firma release.

## Estructura

```text
.
├── .github/
│   └── workflows/
│       └── android.yml
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── car.gd
│   └── main.gd
├── DESIGN.md
├── export_presets.cfg
├── project.godot
└── README.md
```

## Ejecutar localmente

1. Instala Godot 4.3 o superior.
2. Abre `project.godot`.
3. Pulsa **F6/F5**.

Controles de escritorio:

- WASD o flechas: conducir.
- Espacio: drift/freno de mano.
- N: nitro.
- R: restablecer vehículo.

En Android aparecen controles táctiles.

## Generar el APK en GitHub

1. Crea o limpia el repositorio de GitHub.
2. Sube **todo el contenido de esta carpeta a la raíz**.
3. Confirma que exista `.github/workflows/android.yml`.
4. En GitHub abre **Actions**.
5. Selecciona **Build Android APK**.
6. Pulsa **Run workflow**.
7. Cuando termine, descarga el artifact **NeonApex-Android-Debug**.

También se ejecuta automáticamente al modificar el proyecto en la rama `main`.

## Por qué fallaba el workflow anterior

La configuración anterior terminaba usando una exportación **release**. El preset Android estaba firmado, pero no tenía configurado un keystore release, por lo que Godot devolvía:

```text
Cannot export project with preset "Android" due to configuration errors
```

El workflow corregido exporta explícitamente con `--export-debug`, configura Java 17 y Android SDK, crea el debug keystore y muestra diagnóstico antes de compilar.

## APK de publicación

El APK generado por Actions es de **depuración/prueba**. Para Google Play o una distribución release se debe crear un keystore privado permanente y configurar una exportación release. Ese keystore **no debe subirse públicamente al repositorio**.

## Corrección del workflow (runner.temp)

La versión actual evita usar `${{ runner.temp }}` en el `env` global del job. El keystore debug se crea en `$HOME/.android/debug.keystore` durante la ejecución y su ruta se publica mediante `$GITHUB_ENV`. También se configuran explícitamente en Godot el Android SDK, Java 17 y las credenciales del debug keystore.
