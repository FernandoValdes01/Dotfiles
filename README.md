# dotfiles

`~/dotfiles` es la fuente de verdad para un subconjunto auditado de configuraciones y scripts personales. Los archivos originales en `~/.config`, `~/.local/bin` y `~/bin` quedan como symlinks apuntando a este repo.

La selección migrada se hizo con criterios combinados:

- comparación contra defaults de Omarchy cuando existían
- revisión de `mtime` y `ctime`
- inspección de contenido para detectar overrides reales, comentarios/manual edits y scripts propios
- verificación de uso activo por `source`, `import`, `include` o referencias directas
- exclusión de efímeros, backups accidentales, binarios autogenerados y defaults sin cambios reales

## Estructura

```text
~/dotfiles/
├── bin/
├── config/
│   ├── alacritty/
│   ├── hypr/
│   ├── omarchy/current/
│   └── waybar/
├── local/bin/
├── install.sh
├── sync-status.sh
├── backup-originals.sh
├── restore.sh
├── README.md
└── .gitignore
```

## Instalación o reinstalación

Ejecuta:

```bash
cd ~/dotfiles
./install.sh
```

Esto crea directorios faltantes, rehace symlinks y genera backup si necesita reemplazar archivos existentes.

Para simular sin tocar nada:

```bash
./install.sh --dry-run
```

## Verificación

Para validar que cada ruta original siga apuntando al repo:

```bash
./sync-status.sh
```

El script reporta `OK`, `MISSING`, `CONFLICT`, `DRIFT` o `SOURCE_MISSING` y devuelve código distinto de cero si detecta problemas.

## Backups

Antes de relinkear manualmente o de tocar archivos gestionados, puedes crear un backup adicional:

```bash
./backup-originals.sh
```

También puedes respaldar sólo un subconjunto:

```bash
./backup-originals.sh .config/hypr/autostart.conf bin/fix-audio
```

Los backups se guardan por defecto en `~/dotfiles-backups/<timestamp>/` con un `manifest.tsv` y copias exactas de los archivos.

## Restauración

Para restaurar el backup más reciente:

```bash
./restore.sh
```

Para restaurar un backup específico:

```bash
./restore.sh --backup ~/dotfiles-backups/<timestamp>
```

Para restaurar sólo algunos archivos:

```bash
./restore.sh --backup ~/dotfiles-backups/<timestamp> .config/hypr/autostart.conf bin/fix-audio
```

Si la ruta actual ya no es un symlink y existe un archivo regular, `restore.sh` aborta. Usa `--force` sólo si quieres mover ese archivo preexistente al directorio `restore-preexisting/` dentro del backup.

## Agregar un archivo nuevo de forma segura

1. Asegúrate de que realmente sea personalizado y no un default o estado efímero.
2. Crea un backup manual con `./backup-originals.sh <ruta>`.
3. Mueve el archivo al árbol equivalente dentro de `~/dotfiles`.
4. Reemplaza la ruta original por un symlink absoluto al archivo del repo.
5. Ejecuta `./sync-status.sh`.

## Alcance actual

Este repo gestiona actualmente:

- overrides activos de Hypr en `config/hypr/`
- personalizaciones activas de Waybar en `config/waybar/`
- `config/alacritty/alacritty.toml`
- `config/omarchy/current/theme.name`
- scripts propios en `local/bin/` y `bin/`

Defaults stock de Omarchy sin cambios reales, archivos efímeros y binarios autogenerados quedaron fuera a propósito.
