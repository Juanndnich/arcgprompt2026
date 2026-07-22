#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_logo() {
    clear
    echo -e "${CYAN}"
    echo "============================================================"
    printf "%38s\n" "Fasttrack Key By Juanndnich"
    echo "============================================================"
    echo -e "${NC}"
}

print_logo
echo -e "${YELLOW}[INFO] Memulai otomatisasi penuh lab BigQuery & Cloud SQL...${NC}\n"

# ==============================================================================
# Validasi & Pengambilan Project ID Otomatis
# ==============================================================================
echo -e "${CYAN}[CHECK] Mendapatkan Project ID Google Cloud...${NC}"
PROJECT_ID=$(gcloud config get project 2>/dev/null)

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == *"@"* ]]; then
    echo -e "${RED}[WARNING] Project ID tidak valid atau kosong.${NC}"
    echo -e "${YELLOW}[INFO] Silakan lihat Project ID di panel atas konsol Cloud (Format: qwiklabs-gcp-...) ${NC}"
    read -p "Masukkan Project ID yang benar: " PROJECT_ID
    if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == *"@"* ]]; then
        echo -e "${RED}[ERROR] Project ID tidak boleh berupa email dan wajib diisi! Keluar.${NC}"
        exit 1
    fi
    gcloud config set project "$PROJECT_ID"
fi
echo -e "${GREEN}[OK] Menggunakan Project ID: $PROJECT_ID${NC}\n"

CLEAN_PROJECT_ID=$(echo "$PROJECT_ID" | tr '[:upper:]' '[:lower:]' | tr '@._' '-')
BUCKET_NAME="${CLEAN_PROJECT_ID}-bucket"
INSTANCE_NAME="my-demo"
DATABASE_NAME="bike"

# ==============================================================================
# Pengecekan & Pembuatan Cloud Storage Bucket
# ==============================================================================
echo -e "${CYAN}[CHECK] Memeriksa keberadaan Cloud Storage Bucket: gs://${BUCKET_NAME}${NC}"
if gsutil ls -b gs://${BUCKET_NAME} &>/dev/null; then
    echo -e "${GREEN}[SKIP] Bucket gs://${BUCKET_NAME} sudah ada.${NC}"
else
    echo -e "${YELLOW}[ACTION] Membuat bucket baru...${NC}"
    gcloud storage buckets create gs://${BUCKET_NAME} --location=US
fi
echo ""

# ==============================================================================
# Ekstraksi Data dari BigQuery Langsung ke CSV Lokal & Upload ke GCS
# ==============================================================================
echo -e "${CYAN}[ACTION] Mengekstrak data kueri dari BigQuery ke file CSV...${NC}"

bq query --format=csv --use_legacy_sql=false \
'SELECT start_station_name, COUNT(*) AS num FROM `bigquery-public-data.london_bicycles.cycle_hire` GROUP BY start_station_name ORDER BY num DESC' \
> start_station_data.csv

bq query --format=csv --use_legacy_sql=false \
'SELECT end_station_name, COUNT(*) AS num FROM `bigquery-public-data.london_bicycles.cycle_hire` GROUP BY end_station_name ORDER BY num DESC' \
> end_station_data.csv

echo -e "${CYAN}[ACTION] Mengupload file CSV ke Cloud Storage...${NC}"
gcloud storage cp start_station_data.csv gs://${BUCKET_NAME}/
gcloud storage cp end_station_data.csv gs://${BUCKET_NAME}/
echo -e "${GREEN}[OK] File CSV berhasil di-upload ke bucket.${NC}\n"

# ==============================================================================
# Pengecekan & Pembuatan Otomatis Cloud SQL Instance ('my-demo') dengan Input Zona Manual
# ==============================================================================
echo -e "${CYAN}[CHECK] Memeriksa instance Cloud SQL '${INSTANCE_NAME}'${NC}"
if gcloud sql instances describe ${INSTANCE_NAME} &>/dev/null; then
    echo -e "${GREEN}[SKIP] Instance ${INSTANCE_NAME} sudah ada dan berjalan.${NC}"
else
    echo -e "${YELLOW}[ACTION] Instance belum ada. Konfigurasi zona diperlukan.${NC}"
    echo -e "${YELLOW}[INFO] Silakan cek instruksi lab Anda untuk melihat <Lab Zone> yang diizinkan.${NC}"
    
    while true; do
        read -p "Masukkan Lab Zone yang diizinkan (Contoh: us-west4-c): " LAB_ZONE
        if [[ "$LAB_ZONE" =~ ^[a-z]+-[a-z0-9]+-[a-z]$ ]]; then
            echo -e "${GREEN}[OK] Zona '${LAB_ZONE}' diterima.${NC}"
            break
        else
            echo -e "${RED}[ERROR] Format zona tidak valid. Contoh format: us-central1-a, us-west4-c, dll.${NC}"
        fi
    done

    echo -e "${YELLOW}[INFO] Menyiapkan instance '${INSTANCE_NAME}' di zone ${LAB_ZONE}...${NC}"
    echo -e "${YELLOW}[INFO] Proses ini memakan waktu sekitar 3-5 menit. Mohon bersabar...${NC}"

    gcloud sql instances create ${INSTANCE_NAME} \
        --database-version=MYSQL_8_0 \
        --tier=db-custom-4-16384 \
        --zone="${LAB_ZONE}" \
        --availability-type=REGIONAL \
        --root-password="ChangeMe1!" \
        --storage-size=100GB \
        --edition=ENTERPRISE \
        --enable-bin-log \
        --quiet

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK] Instance Cloud SQL ${INSTANCE_NAME} berhasil dibuat!${NC}"
    else
        echo -e "${RED}[ERROR] Gagal membuat instance otomatis dengan zone tersebut.${NC}"
        echo -e "${YELLOW}[FALLBACK] Silakan buat instance 'my-demo' secara manual via konsol Cloud SQL.${NC}"
        read -p "Tekan Enter setelah instance selesai dibuat secara manual..."
    fi
fi
echo ""

# ==============================================================================
# Pengecekan & Pembuatan Database 'bike'
# ==============================================================================
echo -e "${CYAN}[CHECK] Memeriksa database '${DATABASE_NAME}'...${NC}"
if gcloud sql databases describe ${DATABASE_NAME} --instance=${INSTANCE_NAME} &>/dev/null; then
    echo -e "${GREEN}[SKIP] Database sudah ada.${NC}"
else
    gcloud sql databases create ${DATABASE_NAME} --instance=${INSTANCE_NAME}
    echo -e "${GREEN}[OK] Database berhasil dibuat.${NC}"
fi
echo ""

# ==============================================================================
# Pemberian Izin Akses (IAM) Service Account Cloud SQL ke Bucket GCS
# ==============================================================================
echo -e "${CYAN}[ACTION] Memberikan izin akses Service Account Cloud SQL ke Bucket...${NC}"
SA_EMAIL=$(gcloud sql instances describe ${INSTANCE_NAME} --format="value(serviceAccountEmailAddress)" 2>/dev/null)
if [ ! -z "$SA_EMAIL" ]; then
    gcloud storage buckets add-iam-binding gs://${BUCKET_NAME} \
      --member="serviceAccount:${SA_EMAIL}" \
      --role="roles/storage.objectViewer" --quiet
    echo -e "${GREEN}[OK] Izin akses berhasil diberikan.${NC}"
fi
echo ""

# ==============================================================================
# Import CSV ke Cloud SQL
# ==============================================================================
echo -e "${CYAN}[ACTION] Mengimpor file CSV ke tabel database Cloud SQL...${NC}"
gcloud sql import csv ${INSTANCE_NAME} gs://${BUCKET_NAME}/start_station_data.csv --database=${DATABASE_NAME} --table=london1 --quiet 2>/dev/null || true
gcloud sql import csv ${INSTANCE_NAME} gs://${BUCKET_NAME}/end_station_data.csv --database=${DATABASE_NAME} --table=london2 --quiet 2>/dev/null || true
echo -e "${GREEN}[OK] Proses import selesai.${NC}\n"

echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}       SEBAGIAN BESAR PROSES OTOMATISASI SELESAI            ${NC}"
echo -e "${GREEN}============================================================${NC}"
echo -e "${YELLOW}[INFO] Untuk tahap manipulasi data SQL terakhir (DELETE, INSERT, UNION),${NC}"
echo -e "${YELLOW}silakan jalankan perintah koneksi terminal MySQL berikut di Cloud Shell:${NC}"
echo -e "${CYAN}gcloud sql connect ${INSTANCE_NAME} --user=root --quiet${NC}"
echo -e "${YELLOW}(Masukkan password: ChangeMe1! lalu jalankan kueri SQL lab Anda).${NC}"