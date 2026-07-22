#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

clear
echo "============================================================"
printf "%38s\n" "Fasttrack Key By Juanndnich"
echo "============================================================"
echo ""

# ------------------------------------------------------------------------------
# TASK SETUP: Konfigurasi Project ID
# ------------------------------------------------------------------------------
log_info "--- [TASK SETUP] Konfigurasi Project ID ---"
DEFAULT_PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
echo "Project ID aktif saat ini: ${DEFAULT_PROJECT_ID:-'(Tidak terdeteksi)'}"
read -p "Masukkan Google Cloud Project ID Anda [Tekan Enter untuk pakai default]: " INPUT_PROJECT_ID
PROJECT_ID="${INPUT_PROJECT_ID:-$DEFAULT_PROJECT_ID}"

if [[ -z "$PROJECT_ID" ]]; then
    log_error "Project ID tidak boleh kosong!"
    exit 1
fi
log_success "Menggunakan Project ID: $PROJECT_ID"
echo ""

# ------------------------------------------------------------------------------
# TASK 2: Query Public Dataset (natality)
# ------------------------------------------------------------------------------
log_info "--- [TASK 2] Query Public Dataset (natality) ---"
NATALITY_QUERY="SELECT weight_pounds, state, year, gestation_weeks FROM \`bigquery-public-data.samples.natality\` ORDER BY weight_pounds DESC LIMIT 10;"

echo "Query Public Dataset:"
echo -e "${YELLOW}$NATALITY_QUERY${NC}"
read -p "Jalankan query public dataset sekarang? (y/n): " CONFIRM_NATALITY

if [[ "$CONFIRM_NATALITY" == "y" || "$CONFIRM_NATALITY" == "Y" ]]; then
    bq query --use_legacy_sql=false "$NATALITY_QUERY"
    log_success "Query public dataset berhasil dieksekusi!"
else
    log_warn "Query public dataset dilewati."
fi
echo ""

# ------------------------------------------------------------------------------
# TASK 3: Membuat Dataset BigQuery
# ------------------------------------------------------------------------------
log_info "--- [TASK 3] Membuat Dataset BigQuery ---"
DEFAULT_DATASET="babynames"
read -p "Masukkan nama Dataset ID [Default: $DEFAULT_DATASET]: " INPUT_DATASET
DATASET_ID="${INPUT_DATASET:-$DEFAULT_DATASET}"
LOCATION="US"

read -p "Lanjutkan membuat/memeriksa dataset '$DATASET_ID'? (y/n): " CONFIRM_DS
if [[ "$CONFIRM_DS" == "y" || "$CONFIRM_DS" == "Y" ]]; then
    if bq show --dataset "$PROJECT_ID:$DATASET_ID" &>/dev/null; then
        log_warn "Dataset '$Dataset_ID' sudah ada. Melewati pembuatan."
    else
        bq --location="$LOCATION" mk --dataset "$PROJECT_ID:$DATASET_ID"
        log_success "Dataset '$DATASET_ID' berhasil dibuat."
    fi
else
    log_warn "Pembuatan dataset dilewati oleh pengguna."
fi
echo ""

# ------------------------------------------------------------------------------
# TASK 4: Memuat Data dari Cloud Storage ke Tabel Baru (Aman & Tidak Hapus Tabel)
# ------------------------------------------------------------------------------
log_info "--- [TASK 4] Load Data dari GCS ke Tabel ---"
DEFAULT_TABLE="names_2014"
read -p "Masukkan nama Table ID [Default: $DEFAULT_TABLE]: " INPUT_TABLE
TABLE_ID="${INPUT_TABLE:-$DEFAULT_TABLE}"

while true; do
    read -p "Masukkan GCS Source Path (contoh: gs://cloud-training/gsp072/baby-names/yob2014.txt): " GCS_SOURCE
    if [[ "$GCS_SOURCE" =~ ^gs:// ]]; then
        break
    else
        log_error "Format salah! Path GCS harus diawali dengan 'gs://'. Silakan ulangi."
    fi
done

DEFAULT_SCHEMA="name:string,gender:string,count:integer"
read -p "Masukkan Skema Tabel [Default: $DEFAULT_SCHEMA]: " INPUT_SCHEMA
SCHEMA="${INPUT_SCHEMA:-$DEFAULT_SCHEMA}"

echo ""
log_warn "Ringkasan Task 4:"
echo " - Target Tabel : $PROJECT_ID:$DATASET_ID.$TABLE_ID"
echo " - GCS Source   : $GCS_SOURCE"
echo " - Schema       : $SCHEMA"
read -p "Apakah data di atas sudah benar untuk mulai memuat data? (y/n): " CONFIRM_LOAD

if [[ "$CONFIRM_LOAD" == "y" || "$CONFIRM_LOAD" == "Y" ]]; then
    if bq show "$PROJECT_ID:$DATASET_ID.$TABLE_ID" &>/dev/null; then
        log_warn "Tabel '$TABLE_ID' sudah ada. Melewati proses load agar data aman dan tidak terhapus."
    else
        bq load \
            --source_format=CSV \
            --project_id="$PROJECT_ID" \
            "$PROJECT_ID:$DATASET_ID.$TABLE_ID" \
            "$GCS_SOURCE" \
            "$SCHEMA"
        log_success "Data berhasil dimuat ke tabel '$TABLE_ID'."
    fi
else
    log_warn "Proses load data dibatalkan oleh pengguna."
fi
echo ""

# ------------------------------------------------------------------------------
# TASK 6: Menjalankan Custom Query
# ------------------------------------------------------------------------------
log_info "--- [TASK 6] Menjalankan Custom Query ---"
DEFAULT_QUERY="SELECT name, count FROM \`$PROJECT_ID.$DATASET_ID.$TABLE_ID\` WHERE gender = 'M' ORDER BY count DESC LIMIT 5;"

echo "Query custom:"
echo -e "${YELLOW}$DEFAULT_QUERY${NC}"
read -p "Ingin menjalankan query di atas sekarang? (y/n): " CONFIRM_Q

if [[ "$CONFIRM_Q" == "y" || "$CONFIRM_Q" == "Y" ]]; then
    bq query --use_legacy_sql=false "$DEFAULT_QUERY"
    log_success "Query berhasil dieksekusi!"
else
    log_warn "Eksekusi query dilewati."
fi

echo ""
log_success "Semua rangkaian interaktif task lab selesai!"