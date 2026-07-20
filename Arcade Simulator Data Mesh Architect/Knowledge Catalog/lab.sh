#!/bin/bash

# Warna untuk output text
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==========================================
#                  BANNER
# ==========================================
clear
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}                       ARKADEKEY            ${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# 1. Validasi Project ID
echo -e "${YELLOW}[1/5] Memeriksa Project ID Google Cloud...${NC}"
export PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: Project ID tidak ditemukan. Pastikan Anda sudah login di Cloud Shell.${NC}"
    exit 1
else
    echo -e "${GREEN}Project ID Terdeteksi: $PROJECT_ID${NC}"
fi

# Aktifkan API yang dibutuhkan
echo -e "${YELLOW}Mengaktifkan Dataplex API (bila belum aktif)...${NC}"
gcloud services enable dataplex.googleapis.com --project=$PROJECT_ID --quiet

echo -e "\n${CYAN}Tekan ENTER untuk memulai proses otomatisasi...${NC}"
read -r

# ==========================================
# TASK 1: CREATE DATA LAKE SENSORS
# ==========================================
echo -e "${YELLOW}[2/5] Memeriksa Data Lake 'sensors'...${NC}"
LAKE_CHECK=$(gcloud dataplex lakes list --project=$PROJECT_ID --location=us-west1 --filter="name:projects/$PROJECT_ID/locations/us-west1/lakes/sensors" --format="value(name)" 2>/dev/null)

if [ -n "$LAKE_CHECK" ]; then
    echo -e "${GREEN}-> Data lake 'sensors' ALREADY EXISTS. Melanjutkan ke langkah berikutnya...${NC}"
else
    echo -e "${CYAN}-> Membuat Data Lake 'sensors' baru...${NC}"
    gcloud dataplex lakes create sensors \
        --project=$PROJECT_ID \
        --location=us-west1 \
        --display-name="sensors"
    echo -e "${GREEN}Data Lake 'sensors' berhasil dibuat.${NC}"
fi

# ==========================================
# TASK 2: CREATE RAW ZONE
# ==========================================
echo -e "\n${YELLOW}[3/5] Memeriksa Zone 'temperature-raw-data'...${NC}"
ZONE_CHECK=$(gcloud dataplex zones list --lake=sensors --project=$PROJECT_ID --location=us-west1 --filter="name:projects/$PROJECT_ID/locations/us-west1/lakes/sensors/zones/temperature-raw-data" --format="value(name)" 2>/dev/null)

if [ -n "$ZONE_CHECK" ]; then
    echo -e "${GREEN}-> Zone 'temperature-raw-data' ALREADY EXISTS. Validasi pengaturan...${NC}"
else
    echo -e "${CYAN}-> Membuat Zone 'temperature-raw-data'...${NC}"
    # Menggunakan SINGLE_REGION agar tidak terjadi error Invalid Choice REGIONAL
    gcloud dataplex zones create temperature-raw-data \
        --project=$PROJECT_ID \
        --location=us-west1 \
        --lake=sensors \
        --display-name="temperature raw data" \
        --type=RAW \
        --resource-location-type=SINGLE_REGION \
        --discovery-enabled
    echo -e "${GREEN}Zone 'temperature-raw-data' berhasil dibuat.${NC}"
fi

# ==========================================
# TASK 3: CREATE BUCKET & ATTACH ASSET
# ==========================================
echo -e "\n${YELLOW}[4/5] Memeriksa Storage Bucket & Asset...${NC}"
export BUCKET_NAME=$PROJECT_ID

# Cek apakah bucket sudah ada
if gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
    echo -e "${GREEN}-> Bucket gs://$BUCKET_NAME ALREADY EXISTS.${NC}"
else
    echo -e "${CYAN}-> Membuat Bucket Cloud Storage baru...${NC}"
    gcloud storage buckets create gs://$BUCKET_NAME \
        --project=$PROJECT_ID \
        --location=us-west1 \
        --uniform-bucket-level-access
fi

# Cek asset di dataplex
ASSET_CHECK=$(gcloud dataplex assets list --lake=sensors --zone=temperature-raw-data --project=$PROJECT_ID --location=us-west1 --filter="name:projects/$PROJECT_ID/locations/us-west1/lakes/sensors/zones/temperature-raw-data/assets/measurements" --format="value(name)" 2>/dev/null)

if [ -n "$ASSET_CHECK" ]; then
    echo -e "${GREEN}-> Asset 'measurements' ALREADY EXISTS.${NC}"
else
    echo -e "${CYAN}-> Menghubungkan bucket sebagai asset 'measurements'...${NC}"
    gcloud dataplex assets create measurements \
        --project=$PROJECT_ID \
        --location=us-west1 \
        --lake=sensors \
        --zone=temperature-raw-data \
        --display-name="measurements" \
        --resource-type=STORAGE_BUCKET \
        --resource-name=projects/$PROJECT_ID/buckets/$BUCKET_NAME \
        --discovery-enabled
    echo -e "${GREEN}Asset 'measurements' berhasil dihubungkan.${NC}"
fi

# ==========================================
# TASK 4: CLEANUP / DELETE OPTION
# ==========================================
echo -e "\n${CYAN}============================================${NC}"
echo -e "${YELLOW}TASK 1 sampai 3 Selesai! Silakan cek progress di Qwiklabs.${NC}"
echo -e "${CYAN}============================================${NC}"
echo -e "Apakah Anda ingin langsung menjalankan ${RED}TASK 4 (Penghapusan Resource)${NC} sekarang?"
echo -e "Ketik ${GREEN}'yes'${NC} untuk langsung menghapus, atau tekan ${YELLOW}ENTER${NC} untuk keluar."
read -p "Pilihan Anda: " CHOICE

if [ "$CHOICE" = "yes" ]; then
    echo -e "\n${RED}[5/5] Memulai Proses Penghapusan Resource...${NC}"
    
    echo -e "${YELLOW}Menghapus asset 'measurements'...${NC}"
    gcloud dataplex assets delete measurements --project=$PROJECT_ID --location=us-west1 --lake=sensors --zone=temperature-raw-data --quiet 2>/dev/null
    
    echo -e "${YELLOW}Menghapus zone 'temperature-raw-data'...${NC}"
    gcloud dataplex zones delete temperature-raw-data --project=$PROJECT_ID --location=us-west1 --lake=sensors --quiet 2>/dev/null
    
    echo -e "${YELLOW}Menghapus data lake 'sensors'...${NC}"
    gcloud dataplex lakes delete sensors --project=$PROJECT_ID --location=us-west1 --quiet 2>/dev/null
    
    echo -e "${GREEN}Semua resource Dataplex berhasil dihapus! Silakan cek 'Check my progress' terakhir.${NC}"
else
    echo -e "\n${GREEN}Script selesai. Anda dapat menjalankan ulang script ini kapan saja jika diperlukan.${NC}"
fi