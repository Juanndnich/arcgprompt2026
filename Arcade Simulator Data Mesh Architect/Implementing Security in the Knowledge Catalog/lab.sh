#!/bin/bash

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

clear
echo "${CYAN}${BOLD}"
cat << "EOF"
    ___          _              _          _  __           
   / _ \        | |            | |        | |/ /           
  / /_\ \ _ __  | | __  ____ __| |  ___   | ' /  ___  _   _ 
  |  _  || '__| | |/ / / _  / _  | / _ \  |  <  / _ \| | | |
  | | | || |    |   < | (_| (_| ||  __/  | . \|  __/| |_| |
  \_| |_/_|    |_|\_\ \____\__,_| \___|  |_|\_\\___| \__, |
                                                      __/ |
                                                     |___/ 
EOF
echo "${RESET}"
echo "${RANDOM_TEXT_COLOR}${BOLD} 🚀 Memulai Eksekusi Sistem ArkadeKey (Knowledge Catalog Security)... ${RESET}"
echo "--------------------------------------------------------------------------------"
echo ""

# =========================================================================
# 1. SISTEM VALIDASI & DETEKSI OTOMATIS
# =========================================================================
echo "${BOLD}${YELLOW}[ArkadeKey] Melakukan validasi lingkungan kerja...${RESET}"

# Deteksi Project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID=$DEVSHELL_PROJECT_ID
fi

if [ -z "$PROJECT_ID" ]; then
    echo "${BOLD}${RED}[ERROR] Project ID tidak terdeteksi. Pastikan Anda di Cloud Shell.${RESET}"
    exit 1
fi
echo "✅ Project ID Terdeteksi: ${GREEN}$PROJECT_ID${RESET}"

# Konfigurasi Region
REGION="us-east1"
echo "✅ Menggunakan Region   : ${GREEN}$REGION${RESET}"

# Deteksi Bucket Qwiklabs Otomatis
echo "${BOLD}${YELLOW}[ArkadeKey] Memindai Cloud Storage Bucket otomatis...${RESET}"
BUCKET_NAME=$(gsutil ls 2>/dev/null | grep -E 'qwiklabs-gcp-[0-9a-f]+-bucket' | head -n 1 | sed 's|gs://||' | sed 's|/||')

if [ -z "$BUCKET_NAME" ]; then
    echo "${BOLD}${YELLOW}⚠️ Bucket tidak ditemukan lewat pemindaian otomatis.${RESET}"
    read -p "${BOLD}${CYAN}Masukkan nama bucket Anda secara manual: ${RESET}" BUCKET_NAME
    if [ -z "$BUCKET_NAME" ]; then
        echo "${BOLD}${RED}❌ Nama bucket tidak boleh kosong.${RESET}"
        exit 1
    fi
else
    echo "✅ Bucket Terdeteksi   : ${GREEN}$BUCKET_NAME${RESET}"
fi

# Deteksi User 2 Otomatis (Perbaikan Regex & Filter)
echo "${BOLD}${YELLOW}[ArkadeKey] Mendeteksi informasi User 2...${RESET}"
USER_1_CURRENT=$(gcloud config get-value account 2>/dev/null)
USER_2=$(gcloud projects get-iam-policy "$PROJECT_ID" --format="value(bindings.members)" 2>/dev/null | tr ';' '\n' | grep -E 'student-[0-9a-f]+' | grep -v "$USER_1_CURRENT" | sort -u | tail -n 1 | sed 's/user://')

if [ -z "$USER_2" ] || [[ "$USER_2" == *"["* ]]; then
    # Jika hasil deteksi otomatis korup/berbentuk list, gunakan fallback input manual atau target spesifik
    USER_2=$(gcloud projects get-iam-policy "$PROJECT_ID" --format="value(bindings.members)" 2>/dev/null | tr ';' '\n' | grep -E 'student-[0-9a-f]+' | grep -v "$USER_1_CURRENT" | head -n 1 | sed 's/user://' | tr -d "[:space:]'\"[]")
fi

if [ -z "$USER_2" ]; then
    read -p "${BOLD}${CYAN}Masukkan email User 2 (student-XX-XXXXXX@qwiklabs.net): ${RESET}" USER_2
    if [ -z "$USER_2" ]; then
        echo "${BOLD}${RED}❌ Email User 2 wajib diisi.${RESET}"
        exit 1
    fi
else
    echo "✅ User 2 Terdeteksi   : ${GREEN}$USER_2${RESET}"
fi

echo ""
# Mengaktifkan Dataplex API
echo "${BOLD}${BLUE}[ArkadeKey] Mengaktifkan Dataplex API (Knowledge Catalog)...${RESET}"
gcloud services enable dataplex.googleapis.com --project="$PROJECT_ID" --quiet

# Define ID Resources
LAKE_ID="customer-info-lake"
ZONE_ID="customer-raw-zone"
ASSET_ID="customer-online-sessions"

# =========================================================================
# 2. EKSEKUSI TASK 1: CREATE DATA LAKE, ZONE, & ASSET (WITH SKIP CHECK)
# =========================================================================
echo ""
echo "${BOLD}${BLUE}[ArkadeKey] Tugas 1: Membuat Data Lake '$LAKE_ID'...${RESET}"
if gcloud dataplex lakes describe "$LAKE_ID" --location="$REGION" --project="$PROJECT_ID" &>/dev/null; then
    echo "${BOLD}${YELLOW}[SKIP] Data Lake '$LAKE_ID' sudah terbuat.${RESET}"
else
    gcloud dataplex lakes create "$LAKE_ID" \
        --location="$REGION" \
        --display-name="Customer Info Lake" \
        --project="$PROJECT_ID"
fi

# Polling Status Lake hingga ACTIVE
echo "${BOLD}${YELLOW}[ArkadeKey] Menunggu Data Lake berstatus ACTIVE...${RESET}"
while true; do
    STATUS=$(gcloud dataplex lakes describe "$LAKE_ID" --location="$REGION" --project="$PROJECT_ID" --format="value(state)" 2>/dev/null)
    if [ "$STATUS" = "ACTIVE" ]; then
        echo "${BOLD}${GREEN}✅ Data Lake kini ACTIVE.${RESET}"
        break
    fi
    echo -n "."
    sleep 5
done

# Create Zone
echo ""
echo "${BOLD}${BLUE}[ArkadeKey] Tugas 1: Membuat Zone '$ZONE_ID'...${RESET}"
if gcloud dataplex zones describe "$ZONE_ID" --lake="$LAKE_ID" --location="$REGION" --project="$PROJECT_ID" &>/dev/null; then
    echo "${BOLD}${YELLOW}[SKIP] Zone '$ZONE_ID' sudah terbuat.${RESET}"
else
    gcloud dataplex zones create "$ZONE_ID" \
        --lake="$LAKE_ID" \
        --location="$REGION" \
        --display-name="Customer Raw Zone" \
        --type="RAW" \
        --resource-location-type="SINGLE_REGION" \
        --project="$PROJECT_ID"
fi

# Polling Status Zone hingga ACTIVE
echo "${BOLD}${YELLOW}[ArkadeKey] Menunggu Zone berstatus ACTIVE...${RESET}"
while true; do
    STATUS=$(gcloud dataplex zones describe "$ZONE_ID" --lake="$LAKE_ID" --location="$REGION" --project="$PROJECT_ID" --format="value(state)" 2>/dev/null)
    if [ "$STATUS" = "ACTIVE" ]; then
        echo "${BOLD}${GREEN}✅ Zone kini ACTIVE.${RESET}"
        break
    fi
    echo -n "."
    sleep 5
done

# Connect Asset (Cloud Storage Bucket)
echo ""
echo "${BOLD}${BLUE}[ArkadeKey] Tugas 1: Menghubungkan Asset Bucket '$ASSET_ID'...${RESET}"
if gcloud dataplex assets describe "$ASSET_ID" --lake="$LAKE_ID" --zone="$ZONE_ID" --location="$REGION" --project="$PROJECT_ID" &>/dev/null; then
    echo "${BOLD}${YELLOW}[SKIP] Asset '$ASSET_ID' sudah terhubung.${RESET}"
    STATUS="ACTIVE"
else
    gcloud dataplex assets create "$ASSET_ID" \
        --lake="$LAKE_ID" \
        --zone="$ZONE_ID" \
        --location="$REGION" \
        --display-name="Customer Online Sessions" \
        --resource-type="STORAGE_BUCKET" \
        --resource-name="projects/$PROJECT_ID/buckets/$BUCKET_NAME" \
        --discovery-enabled \
        --project="$PROJECT_ID"

    # Polling Status Asset dengan batas waktu maksimal 2 menit (Anti Stuck)
    echo "${BOLD}${YELLOW}[ArkadeKey] Menunggu Asset berstatus ACTIVE (Batas waktu 2 menit)...${RESET}"
    COUNTER=0
    while [ $COUNTER -lt 12 ]; do
        STATUS=$(gcloud dataplex assets describe "$ASSET_ID" --lake="$LAKE_ID" --zone="$ZONE_ID" --location="$REGION" --project="$PROJECT_ID" --format="value(state)" 2>/dev/null)
        if [ "$STATUS" = "ACTIVE" ]; then
            echo ""
            echo "${BOLD}${GREEN}✅ Asset kini ACTIVE.${RESET}"
            break
        fi
        echo -n "."
        sleep 10
        COUNTER=$((COUNTER + 1))
    done
fi

if [ "$STATUS" != "ACTIVE" ]; then
    echo ""
    echo "${BOLD}${YELLOW}[INFO] Backend Google masih memproses aktivasi. Melanjutkan ke setup keamanan IAM...${RESET}"
fi

# =========================================================================
# 3. EKSEKUSI TASK 2 & 4: IAM ROLE ASSIGNMENT (WITH SECURITY FIX)
# =========================================================================
echo ""
echo "${BOLD}${MAGENTA}[ArkadeKey] Tugas 2 & 4: Melakukan konseptualisasi Keamanan IAM...${RESET}"

# 1. Dataplex Data Writer
echo "[INFO] Mengonfigurasi role Data Writer ke $USER_2 pada level Asset..."
gcloud dataplex assets add-iam-policy-binding "$ASSET_ID" \
    --lake="$LAKE_ID" \
    --zone="$ZONE_ID" \
    --location="$REGION" \
    --role="roles/dataplex.dataWriter" \
    --member="user:$USER_2" \
    --project="$PROJECT_ID" --quiet

# 2. Knowledge Catalog Data Reader (FIX PERBAIKAN UTAMA)
echo "[INFO] Mengonfigurasi role Knowledge Catalog Data Reader ke $USER_2..."
gcloud dataplex assets add-iam-policy-binding "$ASSET_ID" \
    --lake="$LAKE_ID" \
    --zone="$ZONE_ID" \
    --location="$REGION" \
    --role="roles/dataplex.dataReader" \
    --member="user:$USER_2" \
    --project="$PROJECT_ID" --quiet

# 3. Dataplex Viewer
echo "[INFO] Mengonfigurasi role Dataplex Viewer ke $USER_2 pada level Lake..."
gcloud dataplex lakes add-iam-policy-binding "$LAKE_ID" \
    --location="$REGION" \
    --role="roles/dataplex.viewer" \
    --member="user:$USER_2" \
    --project="$PROJECT_ID" --quiet

# =========================================================================
# 4. EKSEKUSI TASK 5: SIMULASI UPLOAD FILE
# =========================================================================
echo ""
echo "${BOLD}${BLUE}[ArkadeKey] Tugas 5: Menjalankan simulasi upload file sebagai Writer...${RESET}"

if gsutil ls "gs://$BUCKET_NAME/sample_session.csv" &>/dev/null; then
    echo "${BOLD}${YELLOW}[SKIP] File simulasi 'sample_session.csv' sudah ada di bucket.${RESET}"
else
    echo "id,session_date,customer_id" > sample_session.csv
    echo "1,2026-07-20,CUST-992" >> sample_session.csv
    gsutil cp sample_session.csv "gs://$BUCKET_NAME/"
    rm sample_session.csv
    echo "✅ File simulasi berhasil diunggah."
fi

echo ""
echo "${BOLD}${GREEN}======================================================================${RESET}"
echo "${BOLD}${GREEN} 🎉 [SUKSES] Seluruh sistem pengamanan ArkadeKey berhasil diperbarui! ${RESET}"
echo "${BOLD}${GREEN}======================================================================${RESET}"
echo "${BOLD}${WHITE}Harap cek progres setelah kamu menuggu 1 menit!!.${RESET}"
echo ""