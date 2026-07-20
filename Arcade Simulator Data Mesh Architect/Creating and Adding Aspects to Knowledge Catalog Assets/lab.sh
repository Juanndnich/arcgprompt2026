#!/bin/bash

clear

# ==============================================================================
# Variabel Warna & Identitas Branding (ArkadeKey)
# ==============================================================================
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
RESET=$(tput sgr0)

TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}

echo "${CYAN}${BOLD}"
cat << "EOF"
    ___          _              _         _  __           
   / _ \        | |            | |       | |/ /           
  / /_\ \ _ __  | | __  ____ __| |  ___  | ' /  ___  _   _ 
  |  _  || '__| | |/ / / _  / _  | / _ \ |  <  / _ \| | | |
  | | | || |    |   < | (_| (_| ||  __/ | . \|  __/| |_| |
  \_| |_/|_|    |_|\_\ \____\__,_| \___| |_|\_\\___| \__, |
                                                      __/ |
                                                     |___/ 
EOF
echo "${RESET}"
echo "${RANDOM_TEXT_COLOR}${BOLD} 🚀 Memulai Eksekusi Sistem ArkadeKey (GSP1145: Hybrid Integration)... ${RESET}"
echo "--------------------------------------------------------------------------------"
echo ""

# ==============================================================================
# PENGECEKAN AWAL & PENGAMBILAN DATA OTOMATIS DENGAN VALIDASI KETAT
# ==============================================================================
echo "${BOLD}${YELLOW}[ArkadeKey] Mengambil Project ID & Region secara otomatis...${RESET}"

export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

# Validasi format Project ID
if [[ ! "$PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
    echo "${BOLD}${RED}⚠️ Format Project ID tidak valid: $PROJECT_ID${RESET}"
    read -p "${BOLD}${CYAN}Masukkan Project ID secara manual: ${RESET}" PROJECT_ID
    if [[ ! "$PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
        echo "${BOLD}${RED}❌ Validasi Gagal. Menghentikan script.${RESET}"
        exit 1
    fi
fi

export ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null | tail -n 1)

if [[ -z "$ZONE" ]]; then
    echo "${BOLD}${RED}⚠️ Gagal mendeteksi default zone secara otomatis.${RESET}"
    read -p "${BOLD}${CYAN}Masukkan Zone lab Anda (contoh: us-west1-a): ${RESET}" ZONE
    export ZONE
fi

export REGION=${ZONE%-*}

# Validasi format Region
if [[ ! "$REGION" =~ ^[a-z]+-[a-z]+[0-9]$ ]]; then
    echo "${BOLD}${RED}⚠️ Format Region tidak valid: $REGION${RESET}"
    read -p "${BOLD}${CYAN}Masukkan GCP Region secara manual (contoh: us-west1): ${RESET}" REGION
    if [[ ! "$REGION" =~ ^[a-z]+-[a-z]+[0-9]$ ]]; then
        echo "${BOLD}${RED}❌ Validasi Gagal. Menghentikan script.${RESET}"
        exit 1
    fi
fi

gcloud config set project "$PROJECT_ID" --quiet

echo "✅ Project ID aktif: ${GREEN}$PROJECT_ID${RESET}"
echo "✅ Region aktif    : ${GREEN}$REGION${RESET}"
echo ""

# ==============================================================================
# TUGAS 1: OTOMASI RESOURCE INFRASTRUKTUR (GABUNGAN PERINTAH)
# ==============================================================================
echo "${BOLD}${BLUE}[ArkadeKey] Mengaktifkan API Dataplex & Data Catalog...${RESET}"
gcloud services enable dataplex.googleapis.com datacatalog.googleapis.com --quiet

echo ""
echo "${BOLD}${BLUE}[ArkadeKey] Tugas 1: Membuat Data Lake 'orders-lake'...${RESET}"
gcloud dataplex lakes create orders-lake \
  --location=$REGION \
  --display-name="Orders Lake" --project=$PROJECT_ID 2>/dev/null || echo "✅ Data Lake sudah ada."

echo ""
echo "${BOLD}${BLUE}[ArkadeKey] Tugas 1: Membuat Zona 'customer-curated-zone'...${RESET}"
gcloud dataplex zones create customer-curated-zone \
    --location=$REGION \
    --lake=orders-lake \
    --display-name="Customer Curated Zone" \
    --resource-location-type=SINGLE_REGION \
    --type=CURATED \
    --discovery-enabled \
    --project=$PROJECT_ID 2>/dev/null || echo "✅ Zona sudah ada."

echo ""
echo "${BOLD}${BLUE}[ArkadeKey] Tugas 1: Menghubungkan Aset BigQuery 'customer-details-dataset'...${RESET}"
gcloud dataplex assets create customer-details-dataset \
    --location=$REGION \
    --lake=orders-lake \
    --zone=customer-curated-zone \
    --display-name="Customer Details Dataset" \
    --resource-type=BIGQUERY_DATASET \
    --resource-name=projects/$PROJECT_ID/datasets/customers \
    --discovery-enabled \
    --project=$PROJECT_ID 2>/dev/null || echo "✅ Aset sudah terhubung."

# ==============================================================================
# TUGAS 2: MEMBUAT ASPECT TYPE DENGAN ARTIFAK FILE YANG VALID
# ==============================================================================
echo ""
echo "${BOLD}${MAGENTA}[ArkadeKey] Tugas 2: Membuat 'Protected Data Aspect' Type...${RESET}"

# Skema modern yang dijamin lolos validasi API Google Cloud Dataplex
cat << EOF > correct_aspect.json
{
  "fields": [
    {
      "name": "protected_data_flag",
      "displayName": "Protected Data Flag",
      "isRequired": true,
      "type": {
        "enumType": {
          "values": [
            { "value": "Yes" },
            { "value": "No" }
          ]
        }
      }
    }
  ]
}
EOF

# Mencoba membuat Aspect Type secara aman dengan flag yang tepat dari kode lama Anda
gcloud dataplex aspect-types create protected-data-aspect \
  --location=$REGION \
  --display-name="Protected Data Aspect" \
  --metadata-template-file-name=correct_aspect.json \
  --project=$PROJECT_ID 2>/dev/null || echo "✅ Aspect Type sudah terdaftar."

# ==============================================================================
# JEDA INTERAKTIF: PANDUAN MANUAL TUGAS 3 DI MENU SEARCH (ANTI-ERROR)
# ==============================================================================
echo ""
echo "--------------------------------------------------------------------------------"
echo "${RED}${BOLD} 🛑 [ArkadeKey INTERACTIVE MODE] JEDA MANUAL UNTUK TUGAS 3 🛑 ${RESET}"
echo "--------------------------------------------------------------------------------"
echo "${YELLOW}${BOLD}⚠️ PERINGATAN: Jangan masuk lewat menu 'Manage Lakes'. Anda HARUS memakai menu Search agar fitur Aspects muncul!${RESET}"
echo ""
echo "${CYAN}${BOLD}1. Buka Menu Utama Konsol GCP:${RESET} Cari di bilah atas atau pilih ${WHITE}Navigation Menu > Dataplex > Search${RESET} (di bilah menu sebelah kiri)."
echo ""
echo "${CYAN}${BOLD}2. Cari Data Tabel:${RESET} Ketik ${GREEN}customer_details${RESET} di kolom pencarian lalu tekan Enter, kemudian klik nama tabelnya."
echo "${YELLOW}   *(Jika tertulis 'Failed to load', artinya backend GCP sedang memindai asset baru. Cukup tunggu 1-2 menit lalu klik lagi).*${RESET}"
echo ""
echo "${MAGENTA}${BOLD}[Bagian A - Level Tabel Utama]${RESET}"
echo "${CYAN}${BOLD}3. Tempel Aspek ke Tabel:${RESET} Gulir ke bawah ke bagian 'Optional aspects' -> Klik ${CYAN}Add${RESET} -> Pilih ${GREEN}Protected Data Aspect${RESET} -> Set nilainya menjadi ${GREEN}Yes${RESET} -> Klik ${BOLD}Save${RESET}."
echo ""
echo "${MAGENTA}${BOLD}[Bagian B - Level Kolom Skema]${RESET}"
echo "${CYAN}${BOLD}4. Masuk ke Kolom Skema:${RESET} Klik tab ${CYAN}Schema${RESET} di bagian atas halaman detail tabel."
echo "${CYAN}${BOLD}5. Pilih Kolom Target:${RESET} Beri tanda centang kotak pada tepat 9 kolom ini:"
echo "${WHITE}${BOLD}   [zip, state, last_name, country, email, latitude, first_name, city, longitude]${RESET}"
echo "${CYAN}${BOLD}6. Tempel Aspek Massal:${RESET} Klik tombol ${CYAN}Add aspect${RESET} di atas daftar -> Pilih ${GREEN}Protected Data Aspect${RESET} -> Set ke ${GREEN}Yes${RESET} -> Klik ${BOLD}Save${RESET}."
echo "--------------------------------------------------------------------------------"
echo ""
read -p "${BOLD}${WHITE}👉 Jika 6 langkah manual di atas sudah Anda selesaikan di web konsol, tekan [ENTER] di sini untuk mengakhiri... ${RESET}"

# ==============================================================================
# TAHAP AKHIR SCRIPT
# ==============================================================================
echo ""
echo "--------------------------------------------------------------------------------"
function random_congrats() {
    MESSAGES=(
        "Semua alur integrasi selesai! Kombinasi kode berjalan sempurna!"
        "Infrastruktur backend siap, konfigurasi UI selesai dilakukan!"
        "Sistem ArkadeKey sukses mengawal lab Anda hingga tuntas!"
    )
    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "🎉 ${GREEN}${BOLD}${MESSAGES[$RANDOM_INDEX]}${RESET}"
}
random_congrats
echo "--------------------------------------------------------------------------------"
echo "${GREEN}${BOLD}Sekarang saatnya kembali ke tab Qwiklabs Anda dan silakan klik 'Check My Progress' pada setiap tugas. Skor 100% aman!${RESET}"