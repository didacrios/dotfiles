#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Firefox Snap → APT PPA Migration"
echo "Reemplaza el snap de Firefox (roto) por el repositorio oficial de Mozilla."
echo ""

# 1. Eliminar el snap
echo "📦 [1/5] Eliminando Firefox snap..."
if snap list firefox &>/dev/null; then
    sudo snap remove firefox --purge
    echo "   ✓ Snap eliminado."
else
    echo "   ℹ No se detectó snap de Firefox. Se omite."
fi

# 2. Eliminar paquete transicional y shim
echo "📦 [2/5] Limpiando paquete transicional y shim..."
sudo apt purge -y firefox 2>/dev/null || true
sudo rm -f /usr/bin/firefox
echo "   ✓ Paquete transicional y shim eliminados."

# 3. Agregar el PPA oficial
echo "📦 [3/5] Agregando repositorio PPA de Mozilla..."
if ! sudo add-apt-repository -y ppa:mozillateam/ppa 2>/dev/null; then
    echo "   ⚠ El PPA puede que ya exista. Continuando..."
else
    echo "   ✓ PPA agregado."
fi

# 4. Crear archivo de prioridad APT
echo "📦 [4/5] Configurando prioridad APT para el PPA de Mozilla..."
sudo tee /etc/apt/preferences.d/mozilla-firefox >/dev/null <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
echo "   ✓ Archivo de prioridad creado."

# 5. Actualizar e instalar
echo "📦 [5/5] Actualizando paquetes e instalando Firefox..."
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y firefox
echo "   ✓ Firefox instalado vía APT."

# Verificación
echo ""
echo "✅ Verificación"
echo "  Path:       $(command -v firefox || echo 'no encontrado en PATH')"
echo "  Versión:    $(firefox --version 2>/dev/null || echo 'no disponible')"
echo "  Paquete:    $(dpkg -l firefox 2>/dev/null | awk '/^ii.*firefox/ {print $3}' || echo 'no rastreado por dpkg')"
echo ""
echo "🚀 Listo. Inicia Firefox con: firefox &"
