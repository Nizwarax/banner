#!/bin/bash
# ================================================================
#   PREMIUM VPS INFO BOX  —  Easy Edit Edition
#   Ubah tampilan hanya di bagian CONFIG di bawah
# ================================================================

# ==================== CONFIG (EDIT DI SINI) ====================
OWNER="Deki_niswara"
TITLE="PREMIUM CLOUD VPS"
BOX_WIDTH=54              # Lebar dalam kotak (karakter). Rekomendasi: 50–70
SHOW_FOOTER=true          # true / false
FOOTER_TEXT="Powered by $OWNER"
LABEL_WIDTH=11            # Lebar kolom label (biar rapi). Jangan < 8
BULLET="•"                # Simbol bullet label (bisa diganti ✦, ◆, ›)
# ===============================================================

# ==================== WARNA (opsional diubah) ==================
P='\e[38;5;141m'   # Border (ungu)
L='\e[38;5;105m'   # Label (ungu muda)
V='\e[38;5;120m'   # Value utama (hijau)
B='\e[38;5;81m'    # Value spesial (biru) — dipakai di Region
A='\e[38;5;220m'   # Aksen judul (kuning)
D='\e[38;5;245m'   # Abu (pemisah / footer)
W='\e[0m'
BOLD='\e[1m'
# ===============================================================

# ==================== DETEKSI REGION ===========================
detect_region() {
  local GCP=$(curl -s -m 1 -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/zone 2>/dev/null \
    | awk -F'/' '{print $NF}')
  [[ -n "$GCP" && "$GCP" != *'{'* && ${#GCP} -lt 30 ]] && { echo "$GCP"; return; }

  local AWS=$(curl -s -m 1 http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null)
  [[ -n "$AWS" && "$AWS" != *'{'* && ${#AWS} -lt 30 && "$AWS" != *"404"* ]] && { echo "$AWS"; return; }

  local UPC=$(curl -s -m 1 http://169.254.169.254/metadata/v1.json 2>/dev/null \
    | grep -o '"region":"[^"]*"' | cut -d'"' -f4)
  [[ -n "$UPC" ]] && { echo "$UPC"; return; }

  local AZ=$(curl -s -m 1 -H "Metadata:true" \
    "http://169.254.169.254/metadata/instance/compute/location?api-version=2021-02-01&format=text" 2>/dev/null)
  [[ -n "$AZ" && "$AZ" != *'{'* && ${#AZ} -lt 30 ]] && { echo "$AZ"; return; }

  local DO=$(curl -s -m 1 http://169.254.169.254/metadata/v1/region 2>/dev/null)
  [[ -n "$DO" && "$DO" != *'{'* && "$DO" != *'ERROR'* && ${#DO} -lt 20 ]] && { echo "$DO"; return; }

  local CITY=$(curl -s -m 2 ipinfo.io/city 2>/dev/null | xargs)
  local REG=$(curl -s -m 2 ipinfo.io/region 2>/dev/null | xargs)
  if [[ -n "$REG" && "$REG" != *'{'* ]]; then
    echo "$CITY, $REG" | sed 's/^, //'
    return
  fi
  echo "Unknown"
}
# ===============================================================

# ==================== AMBIL INFO SISTEM ========================
. /etc/os-release
OS="${ID^} ${VERSION_ID} (${HOSTTYPE:-x86_64})"
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs | cut -c1-32)
CORES=$(nproc)
RAM_USED=$(free -h | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
UPTIME=$(awk '{print int($1/3600)"h "int(($1%3600)/60)"m"}' /proc/uptime)
REGION=$(detect_region)
# ===============================================================

# ==================== HELPER UI ================================
hline() { printf '─%.0s' $(seq 1 $BOX_WIDTH); }

center_text() {
  local text="$1"
  local len=${#text}
  local diff=$(( BOX_WIDTH - len ))
  [[ $diff -lt 0 ]] && diff=0
  local pl=$(( diff / 2 ))
  local pr=$(( diff - pl ))
  printf '%*s%s%*s' "$pl" '' "$text" "$pr" ''
}

row() {
  local label="$1" value="$2" color="${3:-$V}"
  local vwidth=$(( BOX_WIDTH - LABEL_WIDTH - 7 ))
  printf "${P}│${W} ${L}${BULLET}${W} ${L}%-${LABEL_WIDTH}s${W} ${D}:${W} ${color}%-${vwidth}s${W} ${P}│${W}\n" \
    "$label" "$value"
}
# ===============================================================

# ==================== RENDER KOTAK =============================
clear

# --- Header atas ---
echo -e "${P}╭$(hline)╮${W}"
printf "${P}│${W}%*s${P}│${W}\n" "$BOX_WIDTH" ''
printf "${P}│${W}${BOLD}${A}%s${W}${P}│${W}\n" "$(center_text "◆  $TITLE  ◆")"
printf "${P}│${W}${V}%s${W}${P}│${W}\n"     "$(center_text "$OS")"
printf "${P}│${W}%*s${P}│${W}\n" "$BOX_WIDTH" ''
echo -e "${P}├$(hline)┤${W}"

# --- Isi informasi ---
row "Owner"  "$OWNER"
row "OS"     "$OS"
row "CPU"    "$CPU"
row "Cores"  "${CORES} Core (vCPU)"
row "RAM"    "${RAM_USED} / ${RAM_TOTAL}"
row "Disk"   "${DISK_USED} / ${DISK_TOTAL}"
row "Uptime" "$UPTIME"
row "Region" "$REGION" "$B"

# --- Footer (opsional) ---
if [[ "$SHOW_FOOTER" == true ]]; then
  echo -e "${P}├$(hline)┤${W}"
  printf "${P}│${W}${D}%s${W}${P}│${W}\n" "$(center_text "$FOOTER_TEXT")"
fi

echo -e "${P}╰$(hline)╯${W}"
# ===============================================================
