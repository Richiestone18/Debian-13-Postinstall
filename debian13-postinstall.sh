#!/bin/bash
###############################################################################
# Script de post-instalación desatendida para Debian 13 (Trixie)
# Compatible con cualquier escritorio: XFCE, GNOME, KDE Plasma, LXQt, i3, Cinnamon, etc.
# No depende de MATE. Ejecutar como root: sudo bash debian13-escritorio-cualquiera-postinstall.sh
###############################################################################

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()  { echo -e "${RED}[ERROR]${NC} $*"; }
header() { echo -e "\n${CYAN}========================================${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}========================================${NC}\n"; }

###############################################################################
# 0. VERIFICACIONES PREVIAS
###############################################################################
header "Verificando requisitos previos"

if [[ $EUID -ne 0 ]]; then
    error "Este script debe ejecutarse como root (sudo)."
    exit 1
fi

REAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo "")}
if [[ -z "$REAL_USER" ]]; then
    error "No se pudo detectar el usuario real. Ejecuta con sudo."
    exit 1
fi
log "Ejecutando para el usuario: $REAL_USER"

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    log "Detectado: $PRETTY_NAME"
fi

if ! ping -c 1 -W 3 deb.debian.org &>/dev/null; then
    error "Sin conexión a internet. Verifica tu red antes de continuar."
    exit 1
fi
log "Conexión a internet OK"

# Preseed para evitar que el script se quede esperando interacción
echo "ttf-mscorefonts-installer msttcorefonts/accept-mscorefonts-eula select true" | debconf-set-selections || true
echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections || true

###############################################################################
# 1. REPOSITORIO MX LINUX
###############################################################################
header "Agregando repositorio MX Linux"

MX_KEYRING="mx25-archive-keyring_2025.03_all.deb"
wget -q "https://mxrepo.com/mx/repo/pool/main/m/mx25-archive-keyring/${MX_KEYRING}" -O "/tmp/${MX_KEYRING}"
dpkg -i "/tmp/${MX_KEYRING}"
rm -f "/tmp/${MX_KEYRING}"

cat > /etc/apt/sources.list.d/mx.sources << 'EOF'
Types: deb
Enabled: yes
URIs: https://mxrepo.com/mx/repo/
Suites: trixie
Components: main non-free ahs
Signed-By: /usr/share/keyrings/mx-25-archive-keyring.gpg
EOF

log "Repositorio MX Linux agregado"

###############################################################################
# 2. REPOSITORIO DEB-MULTIMEDIA
###############################################################################
header "Agregando repositorio deb-multimedia"

DMO_KEYRING="deb-multimedia-keyring_2024.9.1_all.deb"
wget -q "https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/${DMO_KEYRING}" -O "/tmp/${DMO_KEYRING}"
dpkg -i "/tmp/${DMO_KEYRING}"
rm -f "/tmp/${DMO_KEYRING}"

cat > /etc/apt/sources.list.d/dmo.sources << 'EOF'
Types: deb
URIs: https://www.deb-multimedia.org
Suites: trixie
Components: main non-free
Signed-By: /usr/share/keyrings/deb-multimedia-keyring.pgp
Enabled: yes

Types: deb
URIs: https://www.deb-multimedia.org
Suites: trixie-backports
Components: main
Signed-By: /usr/share/keyrings/deb-multimedia-keyring.pgp
Enabled: yes
EOF

log "Repositorio deb-multimedia agregado"

###############################################################################
# 3. REPOSITORIO TRIXIE-BACKPORTS OFICIAL (requerido por varios paquetes abajo)
###############################################################################
header "Asegurando repositorio trixie-backports oficial"

if ! grep -Rq 'trixie-backports' /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" > /etc/apt/sources.list.d/trixie-backports.list
    log "Repositorio trixie-backports agregado"
else
    log "Repositorio trixie-backports ya presente"
fi

###############################################################################
# 4. ACTUALIZAR REPOSITORIOS
###############################################################################
header "Actualizando lista de paquetes"
apt update
apt dist-upgrade -y
log "Repositorios actualizados"

###############################################################################
# 5. FIRMWARE PRINCIPAL (por si no inicia el escritorio)
###############################################################################
header "Instalando firmware principal"

apt install -y firmware-linux-nonfree firmware-amd-graphics firmware-realtek
log "Firmware principal instalado"

###############################################################################
# 6. FIRMWARE COMPLETO PARA DISPOSITIVOS DE RED Y PERIFÉRICOS
###############################################################################
header "Instalando firmware completo de red y periféricos"

apt install -y \
    firmware-ath9k-htc firmware-atheros \
    firmware-b43-installer firmware-b43legacy-installer \
    firmware-bnx2 firmware-bnx2x firmware-brcm80211 \
    firmware-intel-sound firmware-iwlwifi \
    firmware-libertas firmware-misc-nonfree firmware-myricom firmware-netronome \
    firmware-netxen firmware-qlogic \
    firmware-samsung firmware-siano firmware-sof-signed \
    firmware-ti-connectivity firmware-zd1211 \
    firmware-ast firmware-cavium
log "Firmware completo instalado"

###############################################################################
# 7. UTILIDADES Y TWEAKS DEL SISTEMA (sin paquetes de MATE)
###############################################################################
header "Instalando utilidades y tweaks del sistema"

apt install -y \
    papirus-icon-theme arc-theme \
    samba htop btop ttf-mscorefonts-installer gdebi ssh net-tools \
    curl wget git
log "Utilidades y tweaks instalados"

###############################################################################
# 8. PIPEWIRE Y DEPENDENCIAS MULTIMEDIA
###############################################################################
header "Instalando PipeWire y plugins multimedia"

apt install -y \
    pipewire \
    pipewire-alsa \
    pipewire-audio \
    pipewire-bin \
    pipewire-pulse \
    pipewire-jack \
    pipewire-v4l2 \
    wireplumber \
    libspa-0.2-bluetooth \
    libspa-0.2-jack \
    libspa-0.2-libcamera \
    libspa-0.2-modules \
    qpwgraph \
    vlc-plugin-pipewire
log "PipeWire instalado"

###############################################################################
# 9. ACTUALIZAR PIPEWIRE, WIREPLUMBER Y LIBREOFFICE DESDE BACKPORTS
###############################################################################
header "Actualizando PipeWire, WirePlumber y LibreOffice desde backports"

apt install -t trixie-backports -y \
    pipewire \
    pipewire-alsa \
    pipewire-audio \
    pipewire-bin \
    pipewire-pulse \
    pipewire-jack \
    pipewire-v4l2 \
    wireplumber \
    libspa-0.2-bluetooth \
    libspa-0.2-jack \
    libspa-0.2-modules \
    libreoffice \
    libreoffice-l10n-es \
    libreoffice-help-es
log "PipeWire, WirePlumber y LibreOffice actualizados"

###############################################################################
# 10. KERNEL LIQUIX
###############################################################################
header "Instalando kernel Liquorix"

apt dist-upgrade -y

if ! dpkg -l | grep -q liquorix; then
    curl -s 'https://liquorix.net/install-liquorix.sh' | bash
    log "Kernel Liquorix instalado"
else
    log "Kernel Liquorix ya instalado"
fi

###############################################################################
# 11. DRIVERS AMD (64-bit + 32-bit)
###############################################################################
header "Instalando drivers AMD"

dpkg --add-architecture i386
apt update
apt install -y libglx-mesa0:i386 mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 radeontop
log "Drivers AMD instalados"

###############################################################################
# 12. WINE
###############################################################################
header "Instalando Wine"

mkdir -pm755 /etc/apt/keyrings
wget -qO - https://dl.winehq.org/wine-builds/winehq.key | \
    gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key

cat > /etc/apt/sources.list.d/winehq-trixie.sources << 'EOF'
Types: deb
URIs: https://dl.winehq.org/wine-builds/debian
Suites: trixie
Components: main
Architectures: amd64 i386
Signed-By: /etc/apt/keyrings/winehq-archive.key
EOF

apt update
apt install --install-recommends -y winehq-stable
log "Wine instalado"

###############################################################################
# 13. BRAVE BROWSER
###############################################################################
header "Instalando Brave Browser"

curl -fsS https://dl.brave.com/install.sh | sh
log "Brave Browser instalado"

###############################################################################
# 14. ACTUALIZACIÓN FINAL
###############################################################################
header "Actualización final del sistema"

apt update
apt full-upgrade -y
log "Sistema actualizado"

###############################################################################
# 15. HABILITAR PIPEWIRE PARA EL USUARIO
###############################################################################
header "Habilitando PipeWire para $REAL_USER"

USER_UID=$(id -u "$REAL_USER")
XDG_RUNTIME_DIR="/run/user/${USER_UID}"
DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

su - "$REAL_USER" -c "
    export XDG_RUNTIME_DIR='${XDG_RUNTIME_DIR}'
    export DBUS_SESSION_BUS_ADDRESS='${DBUS_SESSION_BUS_ADDRESS}'
    systemctl --user --now disable pulseaudio.{socket,service} || true
    systemctl --user mask pulseaudio || true
    systemctl --user --now enable pipewire{,-pulse}.{socket,service} || true
    systemctl --user --now enable wireplumber.service || true
"

log "PipeWire habilitado para $REAL_USER"

###############################################################################
# 16. KODI Y DEPENDENCIAS
###############################################################################
header "Instalando Kodi y dependencias"

apt install -t trixie-backports -y \
    kodi kodi-audiodecoder-modplug kodi-audiodecoder-openmpt \
    kodi-audiodecoder-sidplay kodi-audioencoder-flac kodi-audioencoder-lame \
    kodi-audioencoder-vorbis kodi-audioencoder-wav kodi-imagedecoder-heif \
    kodi-inputstream-adaptive kodi-inputstream-ffmpegdirect kodi-inputstream-rtmp \
    kodi-peripheral-joystick kodi-pvr-iptvsimple kodi-vfs-libarchive \
    kodi-vfs-rar kodi-vfs-sftp retroarch openrct2
log "Kodi instalado"

###############################################################################
# 17. PROGRAMAS DE DISEÑO GRÁFICO Y MULTIMEDIA
###############################################################################
header "Instalando programas de diseño gráfico y multimedia"

apt install -t trixie-backports -y \
    inkscape inkscape-open-symbols inkscape-speleo inkscape-survex-export \
    inkscape-textext inkscape-textext-doc krita krita-l10n \
    gimp gimp-data-extras scribus scribus-doc scribus-template \
    darktable openshot-qt audacity dvdstyler simplescreenrecorder \
    guvcview amule filezilla qbittorrent blender clipgrab
log "Programas de diseño y multimedia instalados"

###############################################################################
# 18. HERRAMIENTAS DE SEGURIDAD / AUDITORÍA
###############################################################################
header "Instalando herramientas de auditoría de redes"

apt install -y wifite bully hashcat hcxdumptool hcxtools wireshark macchanger
log "Herramientas de seguridad instaladas"

###############################################################################
# 19. LIMPIEZA FINAL
###############################################################################
header "Limpieza final"

apt autoremove -y
apt autoclean
log "Limpieza completada"

###############################################################################
# 20. AUTOLOGIN (según el display manager instalado)
###############################################################################
header "Configurando autologin para $REAL_USER"

configure_autologin_lightdm() {
    mkdir -p /etc/lightdm/lightdm.conf.d
    cat > /etc/lightdm/lightdm.conf.d/01-autologin.conf << EOF
[Seat:*]
autologin-user=${REAL_USER}
autologin-user-timeout=0
EOF
    log "Autologin configurado en LightDM para $REAL_USER"
}

configure_autologin_gdm3() {
    mkdir -p /etc/gdm3/daemon.conf.d
    cat > /etc/gdm3/daemon.conf.d/01-autologin.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=${REAL_USER}
EOF
    log "Autologin configurado en GDM3 para $REAL_USER"
}

configure_autologin_sddm() {
    DESKTOP_SESSION=""
    if [[ -f /usr/share/xsessions/xfce.desktop ]]; then DESKTOP_SESSION="xfce"; \
    elif [[ -f /usr/share/xsessions/gnome.desktop ]]; then DESKTOP_SESSION="gnome"; \
    elif [[ -f /usr/share/xsessions/plasma.desktop ]]; then DESKTOP_SESSION="plasma"; \
    elif [[ -f /usr/share/xsessions/lxqt.desktop ]]; then DESKTOP_SESSION="lxqt"; \
    elif [[ -f /usr/share/xsessions/cinnamon.desktop ]]; then DESKTOP_SESSION="cinnamon"; \
    elif [[ -f /usr/share/xsessions/i3.desktop ]]; then DESKTOP_SESSION="i3"; \
    elif [[ -f /usr/share/xsessions/openbox.desktop ]]; then DESKTOP_SESSION="openbox"; \
    fi
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/01-autologin.conf << EOF
[Autologin]
User=${REAL_USER}
Session=${DESKTOP_SESSION}
EOF
    log "Autologin configurado en SDDM para $REAL_USER (sesión: ${DESKTOP_SESSION:-predeterminada})"
}

if dpkg -s lightdm &>/dev/null || command -v lightdm &>/dev/null; then
    configure_autologin_lightdm
elif dpkg -s gdm3 &>/dev/null || command -v gdm3 &>/dev/null; then
    configure_autologin_gdm3
elif dpkg -s sddm &>/dev/null || command -v sddm &>/dev/null; then
    configure_autologin_sddm
else
    warn "No se detectó un display manager instalado (lightdm, gdm3 o sddm)."
    warn "El autologin no se configuró. Instala uno y vuelve a ejecutar esta parte si lo necesitas."
fi

###############################################################################
# FIN
###############################################################################
header "INSTALACIÓN COMPLETADA"

echo ""
log "Todo instalado correctamente."
echo ""
warn "Se recomienda REINICIAR para aplicar el kernel Liquorix y todos los cambios."
echo ""
echo "  sudo reboot"
echo ""
echo "Nota: este script no aplica tema, iconos ni panel automáticamente porque esos"
echo "ajustes dependen de cada escritorio (XFCE, GNOME, KDE, etc.). Instala y aplica"
echo "el tema Arc-Dark y los iconos Papirus-Dark desde los ajustes de tu entorno."
echo ""
