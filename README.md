# Dotfiles

Este repositorio contiene la parte de mi entorno que considero realmente mía: overrides activos, ajustes de flujo de trabajo y scripts personales que uso sobre Arch Linux con Omarchy.

Mi objetivo aquí no es copiar todo mi `$HOME`, sino mantener una base pequeña, entendible y mantenible. Por eso este repo funciona con symlinks: la fuente de verdad vive en `~/Documents/Github/Dotfiles`, y las rutas originales en `~/.config`, `~/.local/bin` y `~/bin` apuntan hacia acá.

## Cómo está pensado este repo

Yo separo mis dotfiles con una idea simple:

- los defaults del sistema o de Omarchy no se editan directamente
- mis cambios viven como overrides claros y localizados
- sólo versiono lo que vale la pena mantener
- todo lo que migro debe poder restaurarse

Eso significa que aquí no guardo caches, estado efímero, binarios autogenerados ni archivos que existan sólo como copia de un default sin cambios reales.

## Mapa rápido

```text
~/Documents/Github/Dotfiles/
├── bin/                     # scripts personales en ~/bin
├── config/
│   ├── alacritty/           # configuración del terminal Alacritty
│   ├── hypr/                # overrides de Hyprland
│   ├── omarchy/current/     # estado persistente que sí decidí guardar
│   └── waybar/              # barra, módulos y estilo
├── local/bin/               # scripts personales en ~/.local/bin
├── install.sh               # recrea symlinks de forma segura
├── sync-status.sh           # verifica si todo sigue apuntando bien
├── backup-originals.sh      # hace backups manuales antes de relinkear
├── restore.sh               # restaura backups si algo falla
├── README.md
└── .gitignore
```

## Qué puede tomar otra persona de este repo

Si alguien quiere reutilizar ideas de aquí, esto es lo más portable:

- `config/waybar/`: un punto de partida claro para Waybar con una personalización mínima y legible
- `config/alacritty/alacritty.toml`: una configuración de terminal simple, pensada para integrarse con un tema externo
- `config/hypr/input.conf`: buenas ideas de layout, repetición, touchpad y ergonomía
- `config/hypr/looknfeel.conf`: un override pequeño para cambiar bordes y estética sin reescribir todo Hyprland
- `bin/` y `local/bin/`: scripts concretos que muestran cómo automatizo tareas frecuentes

Lo menos portable, y por tanto lo primero que yo revisaría si alguien lo clona:

- `config/hypr/monitors.conf`: depende de mi hardware y mi disposición de monitores
- `bin/fix-audio` y `local/bin/fix-audio.sh`: están escritos alrededor de mi stack de audio y mi tarjeta
- `local/bin/set-wallpaper.sh`: depende de mi ruta de wallpapers y de `swww`
- `config/omarchy/current/theme.name`: expresa una preferencia personal de tema

## Qué hace cada parte

### `config/hypr/`

Aquí guardo mis overrides activos de Hyprland. No intento duplicar toda la configuración base de Omarchy; sólo pongo lo que quiero cambiar de verdad.

- `hyprland.conf`: archivo raíz. Carga defaults de Omarchy, luego carga mis overrides y añade algunas variables específicas de mi equipo.
- `autostart.conf`: procesos extra que quiero lanzar al iniciar sesión.
- `bindings.conf`: atajos de teclado personalizados y accesos rápidos a apps y webapps que uso a diario.
- `input.conf`: layout de teclado, repetición, numlock, touchpad y algunas reglas de scroll.
- `looknfeel.conf`: cambios visuales pequeños, especialmente bordes y apariencia general.
- `monitors.conf`: disposición y escala de monitores. Esta parte es claramente dependiente de hardware.
- `hyprlock.conf`: ajustes del lockscreen, sobre todo integración visual y fuente.

### `config/waybar/`

Aquí está mi configuración de Waybar.

- `config.jsonc`: define módulos, orden, comportamiento e interacciones.
- `style.css`: ajusta la presentación visual de la barra y se apoya en el tema actual de Omarchy.

Mi intención aquí fue mantener una barra limpia y legible, con cambios suficientes para que se sienta propia sin convertirla en una hoja de estilo inmanejable.

### `config/alacritty/`

Aquí dejo la parte de Alacritty que realmente quiero controlar.

- `alacritty.toml`: importa el tema activo de Omarchy y luego define mi fuente, tamaño, padding, decoración y atajos de teclado.

La idea es separar color y tema de terminal, que cambian con Omarchy, de mis preferencias de uso, que son más estables.

### `config/omarchy/current/`

No guardo todo el estado generado por Omarchy. Sólo versiono lo que considero útil mantener como preferencia real.

- `theme.name`: registra el tema que quiero dejar activo por defecto.

### `local/bin/`

Scripts personales que cuelgan de `~/.local/bin`.

- `fix-audio.sh`: intenta normalizar mute y volumen al inicio.
- `set-wallpaper.sh`: aplica un wallpaper concreto usando `swww`.

### `bin/`

Scripts personales que cuelgan de `~/bin`.

- `fix-audio`: variante de ajuste de audio más específica para una tarjeta concreta.
- `gitbackup`: restaura backups guardados del directorio `.git` de un repo.
- `gitclean`: limpia backups viejos y conserva el más reciente.
- `gitsafe`: recorre repositorios y guarda snapshots de sus metadatos Git.

## Cómo funciona la instalación

Las rutas originales no son copias: son symlinks.

Ejemplo:

```text
~/.config/waybar/style.css
-> ~/Documents/Github/Dotfiles/config/waybar/style.css
```

Eso significa que si edito el archivo dentro del repo, el cambio se refleja de inmediato en la ruta original.

Para recrear los symlinks:

```bash
cd ~/Documents/Github/Dotfiles
./install.sh
```

Para simular sin tocar nada:

```bash
./install.sh --dry-run
```

## Cómo verifico que todo sigue sano

Uso este script:

```bash
cd ~/Documents/Github/Dotfiles
./sync-status.sh
```

El resultado puede mostrar:

- `OK`: el symlink existe y apunta al archivo correcto del repo
- `MISSING`: falta la ruta original
- `CONFLICT`: existe algo en la ruta original, pero no es el symlink esperado
- `DRIFT`: existe un symlink, pero apunta a otro lugar
- `SOURCE_MISSING`: el repo referencia un archivo que ya no existe

## Backups y restauración

Antes de relinkear manualmente o tocar algo delicado, puedo crear un backup adicional:

```bash
./backup-originals.sh
```

También puedo respaldar sólo un subconjunto:

```bash
./backup-originals.sh .config/hypr/autostart.conf bin/fix-audio
```

Si necesito volver atrás:

```bash
./restore.sh
```

O restaurar un backup específico:

```bash
./restore.sh --backup ~/dotfiles-backups/<timestamp>
```

La lógica de restauración está pensada para ser conservadora: si encuentra un estado inconsistente, prefiere abortar antes que sobrescribir silenciosamente.

## Cómo agrego un archivo nuevo

Si quiero incorporar un archivo nuevo a este repo, mi criterio es este:

1. Confirmo que sea realmente una personalización y no una copia de un default.
2. Verifico que no sea cache, estado efímero o archivo autogenerado.
3. Hago backup con `./backup-originals.sh <ruta>`.
4. Lo muevo al árbol correspondiente dentro del repo.
5. Reemplazo la ruta original por un symlink.
6. Corro `./sync-status.sh`.

