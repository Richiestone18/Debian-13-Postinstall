# Debian-13-Postinstall

Script de post-instalación desatendida para **Debian 13 (Trixie)**, compatible con **cualquier escritorio**: XFCE, GNOME, KDE Plasma, LXQt, i3, Cinnamon, etc.

No depende de **MATE**. No instala extensiones de Caja, no configura panel de MATE vía dconf, ni asume un display manager específico.

## ¿Qué hace?

- **Repositorios:** agrega MX Linux (trixie), deb-multimedia (trixie + trixie-backports) y el oficial `trixie-backports` de Debian.
- **Actualización del sistema:** `apt update` + `dist-upgrade` + `full-upgrade` final.
- **Firmware:** firmware principal (Linux, AMD, Realtek) y firmware completo de red/periféricos (Atheros, Broadcom, Intel, iwlwifi, QLogic, etc.).
- **Utilidades del sistema:** htop, btop, samba, gdebi, net-tools, ssh, curl, wget, git, temas Arc-Dark e iconos Papirus-Dark.
- **PipeWire + WirePlumber:** reemplaza a PulseAudio con todos los plugins multimedia (ALSA, Bluetooth, JACK, Libcamera, V4L2, XRDP).
- **Kernel Liquorix:** instala el kernel Liquorix si no está presente.
- **Drivers AMD:** Mesa Vulkan y libGL de 64 y 32 bits, radeontop.
- **WineHQ Stable:** repositorio oficial de WineHQ.
- **Brave Browser:** instalador oficial (`curl | sh`).
- **Kodi 21 + dependencias:** decodificadores, inputstream, PVR, VFS, RetroArch, OpenRCT2.
- **Diseño y multimedia:** Inkscape, Krita, GIMP, Scribus, Darktable, OpenShot, Audacity, DVDStyler, SimpleScreenRecorder, GuvcView, aMule, FileZilla, qBittorrent, Blender, ClipGrab.
- **Seguridad / Auditoría:** Wifite, Bully, Hashcat, hcxdumptool, hcxtools, Wireshark, Macchanger.
- **Autologin:** detecta automáticamente LightDM, GDM3 o SDDM y configura el inicio automático para el usuario que ejecutó el script. Si no hay ninguno instalado, avisa y salta ese paso.
- **Limpieza:** `apt autoremove` y `apt autoclean`.

## Escritorios compatibles

Este script es **entorno-agnóstico**. Funciona igual en:

- XFCE
- GNOME
- KDE Plasma
- LXQt
- i3
- Cinnamon
- Openbox
- Cualquier otro escritorio disponible en Debian 13

> **Nota:** el tema Arc-Dark y los iconos Papirus-Dark se instalan, pero **no se aplican automáticamente** porque cada escritorio gestiona sus ajustes distinto. Aplícalos desde los ajustes de tu entorno (Apariencia / Aspecto / Temas).

## Requisitos

- Debian 13 (Trixie) recién instalado
- Conexión a internet
- Ejecutar como root (`sudo`)
- `trixie-backports` disponible (el script lo agrega automáticamente si falta)

## Uso

Descarga directa con `wget`:

```bash
wget https://raw.githubusercontent.com/Richiestone18/Debian-13-Postinstall/main/debian13-postinstall.sh
chmod +x debian13-postinstall.sh
sudo bash debian13-postinstall.sh
```

O sin descargar:

```bash
wget -qO - https://raw.githubusercontent.com/Richiestone18/Debian-13-Postinstall/main/debian13-postinstall.sh | sudo bash
```

Al terminar, reinicia para aplicar el kernel Liquorix y todos los cambios:

```bash
sudo reboot
```

## Notas importantes

- El script se detiene si algún comando falla (`set -euo pipefail`).
- Preseed de `ttf-mscorefonts-installer` y `wireshark-common` para no quedar esperando interacción.
- Brave y el kernel Liquorix se instalan mediante scripts remotos de sus creadores oficiales.
- Brave, WineHQ y Liquorix son opcionales; puedes editarlos o comentarlos antes de ejecutar si no los necesitas.
- Si usas i3 u otro entorno sin display manager, el autologin se omite y lo configuras tú manualmente.

## Créditos

Basado en los manuales de Richiestone.
