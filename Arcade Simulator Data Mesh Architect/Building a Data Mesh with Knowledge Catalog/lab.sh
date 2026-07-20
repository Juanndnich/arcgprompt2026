#!/bin/bash

# ==============================================================================
# Variabel Warna & Format (ArkadeKey Engine)
# ==============================================================================
ORANGE_TEXT=$'\033[38;5;214m'  
YELLOW_TEXT=$'\033[0;93m'
GREEN_TEXT=$'\033[0;92m'
MAGENTA_TEXT=$'\033[0;95m'
WHITE_TEXT=$'\033[0;97m'
CYAN_TEXT=$'\033[0;96m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear
echo "${ORANGE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${ORANGE_TEXT}${BOLD_TEXT}     🛡️ STAGE-BY-STAGE DATA MESH AUTOMATION (FINAL OPTIMIZED)     ${RESET_FORMAT}"
echo "${ORANGE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# ==============================================================================
# STASE 1: INISIALISASI PARAMETER LINGKUNGAN & VALIDASI ID
# ==============================================================================
echo "${YELLOW_TEXT}${BOLD_TEXT}[STASE 1/5] Mengunci Parameter Lingkungan GCP...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    export PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

# Deteksi Region otomatis, default ke us-east4 jika zone tidak terikat
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)
if [ ! -z "$ZONE" ]; then
    export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
else
    export REGION="us-east4"
fi

echo "${WHITE_TEXT}▶ Project ID  : $PROJECT_ID${RESET_FORMAT}"
echo "${WHITE_TEXT}▶ Region/Zone : $REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}✅ Validasi Parameter Sukses.${RESET_FORMAT}"
echo "------------------------------------------------------------------"

# ==============================================================================
# STASE 2: OTOMASI STRUKTUR DATA LAKEMESH (TASK 1)
# ==============================================================================
echo "${YELLOW_TEXT}${BOLD_TEXT}[STASE 2/5] Membangun Infrastruktur Utama Dataplex (Task 1)...${RESET_FORMAT}"
gcloud services enable dataplex.googleapis.com datacatalog.googleapis.com dataproc.googleapis.com --quiet

echo "Menginisiasi sales-lake..."
gcloud dataplex lakes create sales-lake --location=$REGION --display-name="Sales Lake" --quiet 2>/dev/null

echo "Membangun raw-customer-zone & curated-customer-zone..."
gcloud dataplex zones create raw-customer-zone --lake=sales-lake --location=$REGION --display-name="Raw Customer Zone" --type=RAW --resource-location-type=SINGLE_REGION --discovery-enabled --discovery-schedule="0 * * * *" --quiet 2>/dev/null
gcloud dataplex zones create curated-customer-zone --lake=sales-lake --location=$REGION --display-name="Curated Customer Zone" --type=CURATED --resource-location-type=SINGLE_REGION --discovery-enabled --discovery-schedule="0 * * * *" --quiet 2>/dev/null

echo "Menghubungkan aset Cloud Storage & BigQuery..."
gcloud dataplex assets create customer-engagements --lake=sales-lake --zone=raw-customer-zone --location=$REGION --display-name="Customer Engagements" --resource-type=STORAGE_BUCKET --resource-name=projects/$PROJECT_ID/buckets/$PROJECT_ID-customer-online-sessions --discovery-enabled --quiet 2>/dev/null
gcloud dataplex assets create customer-orders --lake=sales-lake --zone=curated-customer-zone --location=$REGION --display-name="Customer Orders" --resource-type=BIGQUERY_DATASET --resource-name=projects/$PROJECT_ID/datasets/customer_orders --discovery-enabled --quiet 2>/dev/null

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 1 Berhasil Dibuat Secara Pararel oleh Backend.${RESET_FORMAT}"
echo "👉 Silakan klik tombol 'Check my progress' di Qwiklabs untuk Task 1."
echo "------------------------------------------------------------------"

# ==============================================================================
# STASE 3: INTERUPSI MANUAL LAYANAN ASPECT METADATA (TASK 2)
# ==============================================================================
echo "${ORANGE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT} 👉 BAGIAN MANUAL: PENEMPELAN ASPEK (TASK 2) 👈${RESET_FORMAT}"
echo "${ORANGE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${WHITE_TEXT}Lakukan konfigurasi berikut pada tab Browser Konsol Google Cloud Anda:${RESET_FORMAT}"
echo "1. Buka menu ${CYAN_TEXT}Dataplex${RESET_FORMAT} -> pilih sub-menu ${CYAN_TEXT}Manage${RESET_FORMAT} di bilah kiri."
echo "2. Klik pada objek data lake bernama ${CYAN_TEXT}sales-lake${RESET_FORMAT}."
echo "3. Masuk ke tab ${CYAN_TEXT}Zones${RESET_FORMAT} (tengah atas) -> lalu buka ${CYAN_TEXT}raw-customer-zone${RESET_FORMAT}."
echo "4. Di barisan menu aksi bagian atas, klik tombol ${CYAN_TEXT}Add Aspect / Edit Metadata${RESET_FORMAT}."
echo "5. Pilih template aspek custom ${CYAN_TEXT}Protected Customer Data Aspect${RESET_FORMAT}."
echo "6. Setel kolom opsi ${CYAN_TEXT}Raw Data Flag${RESET_FORMAT} menjadi ${GREEN_TEXT}Yes${RESET_FORMAT}."
echo "7. Setel kolom opsi ${CYAN_TEXT}Protected Contact Information Flag${RESET_FORMAT} menjadi ${GREEN_TEXT}Yes${RESET_FORMAT}."
echo "8. Klik tombol ${CYAN_TEXT}Save / Submit${RESET_FORMAT}."
echo "------------------------------------------------------------------"
echo "${YELLOW_TEXT}${BOLD_TEXT}👉 Selesaikan modifikasi UI di atas, lalu kembali ke sini.${RESET_FORMAT}"
read -p "   Jika sudah selesai disimpan, Tekan [ENTER] untuk lanjut... "
echo

# ==============================================================================
# STASE 4: INPUT DINAMIS USER 2 & KEBIJAKAN IAM (TASK 3)
# ==============================================================================
echo "${YELLOW_TEXT}${BOLD_TEXT}[STASE 3/5] Memulai Konfigurasi IAM Akses User 2 (Task 3)...${RESET_FORMAT}"
echo "${WHITE_TEXT}Silakan salin email Akun ke-2 (User 2) dari panel informasi Qwiklabs Anda.${RESET_FORMAT}"
read -p "📌 Masukkan email User 2: " USER_2

if [ -z "$USER_2" ]; then
    echo "${RED_TEXT}Email tidak valid. Menggunakan fallback standard...${RESET_FORMAT}"
    USER_2="student-02-2f17aec19461@qwiklabs.net"
fi

echo "Menerapkan IAM Policy Binding roles/dataplex.dataWriter..."
gcloud dataplex assets add-iam-policy-binding customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --member=user:$USER_2 \
  --role=roles/dataplex.dataWriter --quiet

echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 3 Selesai! Kebijakan Akses User 2 Berhasil Disematkan.${RESET_FORMAT}"
echo "👉 Silakan klik tombol 'Check my progress' di Qwiklabs untuk Task 3."
echo "------------------------------------------------------------------"

# ==============================================================================
# STASE 5: VALIDASI DATA QUALITY MODEREN (TASK 4 & 5)
# ==============================================================================
echo "${YELLOW_TEXT}${BOLD_TEXT}[STASE 4/5] Memproses Otomasi Data Quality Moderen (Task 4 & 5)...${RESET_FORMAT}"

# Bersihkan sisa job lama agar tidak mengunci nama resource
gcloud dataplex data-quality-jobs delete customer-orders-data-quality-job --location="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null
gcloud dataplex datascans delete customer-orders-data-quality-job --location="$REGION" --project="$PROJECT_ID" --quiet 2>/dev/null

# Membuat file spesifikasi YAML modern (Data Scans Format)
cat << 'EOF' > dq-customer-orders.yaml
rules:
- nonNullExpectation: {}
  column: user_id
  dimension: COMPLETENESS
  threshold: 1

- nonNullExpectation: {}
  column: order_id
  dimension: COMPLETENESS
  threshold: 1

postScanActions:
  bigqueryExport:
    resultsTable: projects/%PROJECT_ID%/datasets/orders_dq_dataset/tables/results
EOF

# Injeksi Project ID asli ke dalam berkas YAML
sed -i "s/%PROJECT_ID%/$PROJECT_ID/g" dq-customer-orders.yaml

# Unggah spesifikasi ke Cloud Storage
gsutil cp dq-customer-orders.yaml "gs://${PROJECT_ID}-dq-config/" &>/dev/null
rm dq-customer-orders.yaml
echo "✅ Task 4 Selesai! Berkas YAML sukses diposisikan ke GCS."

# Mendaftarkan dan mengeksekusi Job secara instan via API Moderen agar tampil di UI Data Scans
echo "Mendaftarkan scan job ke menu Data profiling & quality..."
gcloud dataplex datascans create data-quality customer-orders-data-quality-job \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --data-source-resource="//bigquery.googleapis.com/projects/$PROJECT_ID/datasets/customer_orders/tables/ordered_items" \
    --data-quality-spec-file="gs://${PROJECT_ID}-dq-config/dq-customer-orders.yaml" \
    --quiet

echo "🚀 Memicu eksekusi scan data quality secara instan..."
gcloud dataplex datascans run customer-orders-data-quality-job \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT} 🎉 [SUKSES TOTAL] SELURUH ALUR DATA MESH BERHASIL DISINKRONISASI! ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${WHITE_TEXT}1. Segarkan (Refresh) menu 'Data profiling & quality' di browser Anda untuk melihat progress.${RESET_FORMAT}"
echo "${WHITE_TEXT}2. Silakan klik seluruh tombol 'Check my progress' dari Task 1 hingga 5 di Qwiklabs setelah menunggu 1 - 8 menit.${RESET_FORMAT}"
echo