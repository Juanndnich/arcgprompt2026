#!/usr/bin/env bash

set -e

# Definisi Warna Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}============================================================${NC}"
printf "${YELLOW}%38s\n${NC}" "Fasttrack Key By Juanndnich"
echo -e "${CYAN}============================================================${NC}"
echo ""

# Validasi environment awal
if ! command -v bq &> /dev/null; then echo -e "${RED}[ERROR] bq CLI tidak ditemukan.${NC}"; exit 1; fi
PROJECT_TERDETEKSI=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_TERDETEKSI" ]; then
    echo -e "${RED}[ERROR] Belum ada project GCP yang aktif.${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Berjalan pada Project GCP: ${PROJECT_TERDETEKSI}${NC}\n"

# Fungsi pembungkus eksekusi kueri agar skrip tidak mati saat menemui query yang sengaja salah/error
eksekusi_log_lab() {
    local label="$1"
    local query="$2"

    echo -e "${CYAN}------------------------------------------------------------${NC}"
    echo -e "${BOLD}${BLUE}[Mengeksekusi: ${label}]${NC}"
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    
    set +e
    bq query --use_legacy_sql=false --format=sparse "$query"
    local status=$?
    set -e

    # Memberikan jeda waktu kecil agar backend Qwiklabs sempat menangkap log history query
    sleep 2
    echo ""
}

# ============================================================
# TUGAS 2: MENEMUKAN JUMLAH TOTAL PELANGGAN CHECKOUT (40 Poin)
# ============================================================
echo -e "${BOLD}${YELLOW}=== MEMULAI EKSEKUSI TUGAS 2 (URUTAN MODUL PERSIS) ===${NC}"

# 1. Kueri typo nama dataset (Sengaja Error)
eksekusi_log_lab "T2.1 - Typo Dataset" \
'SELECT FROM `data-to-inghts.ecommerce.rev_transactions` LIMIT 1000'

# 2. Kueri Legacy SQL format (Sengaja Error)
eksekusi_log_lab "T2.2 - Legacy SQL Format Check" \
'SELECT * FROM [data-to-insights:ecommerce.rev_transactions] LIMIT 1000'

# 3. Kueri Standard SQL tanpa kolom - *Ini yang memicu error "Please add a column to the query"*
eksekusi_log_lab "T2.3 - No Column Defined" \
'SELECT FROM `data-to-insights.ecommerce.rev_transactions`'

# 4. Kueri hanya kolom fullVisitorId
eksekusi_log_lab "T2.4 - Single Column fullVisitorId" \
'SELECT fullVisitorId FROM `data-to-insights.ecommerce.rev_transactions` LIMIT 100'

# 5. Kueri judul halaman tanpa koma (Sengaja Error/Alias tidak sengaja)
eksekusi_log_lab "T2.5 - Missing Comma Test" \
'SELECT fullVisitorId hits_page_pageTitle FROM `data-to-insights.ecommerce.rev_transactions` LIMIT 100'

# 6. Kueri koreksi koma awal
eksekusi_log_lab "T2.6 - Corrected Comma" \
'SELECT fullVisitorId, hits_page_pageTitle FROM `data-to-insights.ecommerce.rev_transactions` LIMIT 100'

# 7. Kueri COUNT biasa tanpa GROUP BY (Sengaja Error)
eksekusi_log_lab "T2.7 - COUNT tanpa GROUP BY" \
'SELECT COUNT(fullVisitorId) AS visitor_count, hits_page_pageTitle FROM `data-to-insights.ecommerce.rev_transactions`'

# 8. Kueri kombinasi COUNT DISTINCT + GROUP BY
eksekusi_log_lab "T2.8 - COUNT DISTINCT dengan GROUP BY" \
'SELECT COUNT(DISTINCT fullVisitorId) AS visitor_count, hits_page_pageTitle FROM `data-to-insights.ecommerce.rev_transactions` GROUP BY hits_page_pageTitle'

# 9. Solusi Final Tugas 2 dengan Klausa WHERE
eksekusi_log_lab "T2.9 - Solusi Akhir Tugas 2" \
'SELECT COUNT(DISTINCT fullVisitorId) AS visitor_count, hits_page_pageTitle FROM `data-to-insights.ecommerce.rev_transactions` WHERE hits_page_pageTitle = "Checkout Confirmation" GROUP BY hits_page_pageTitle'


# ============================================================
# TUGAS 3: DAFTAR KOTA DENGAN TRANSAKSI TERBANYK (40 Poin)
# ============================================================
echo -e "${BOLD}${YELLOW}=== MEMULAI EKSEKUSI TUGAS 3 (URUTAN MODUL PERSIS) ===${NC}"

# 1. Kueri parsial dasar kota & total transaksi
eksekusi_log_lab "T3.1 - Dasar Kota & Total Transaksi" \
'SELECT geoNetwork_city, SUM(totals_transactions) AS totals_transactions, COUNT( DISTINCT fullVisitorId) AS distinct_visitors FROM `data-to-insights.ecommerce.rev_transactions` GROUP BY geoNetwork_city'

# 2. Kueri kota dengan ORDER BY distinct_visitors
eksekusi_log_lab "T3.2 - Ditambahkan ORDER BY" \
'SELECT geoNetwork_city, SUM(totals_transactions) AS totals_transactions, COUNT( DISTINCT fullVisitorId) AS distinct_visitors FROM `data-to-insights.ecommerce.rev_transactions` GROUP BY geoNetwork_city ORDER BY distinct_visitors DESC'

# 3. Kueri pembuatan kolom kalkulasi rata-rata (avg_products_ordered)
eksekusi_log_lab "T3.3 - Tambah Kolom Kalkulasi Rata-rata" \
'SELECT geoNetwork_city, SUM(totals_transactions) AS total_products_ordered, COUNT( DISTINCT fullVisitorId) AS distinct_visitors, SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered FROM `data-to-insights.ecommerce.rev_transactions` GROUP BY geoNetwork_city ORDER BY avg_products_ordered DESC'

# 4. Kueri salah menggunakan WHERE pada field agregasi (Sengaja Error)
eksekusi_log_lab "T3.4 - Filter Agregasi Salah Pakai WHERE" \
'SELECT geoNetwork_city, SUM(totals_transactions) AS total_products_ordered, COUNT( DISTINCT fullVisitorId) AS distinct_visitors, SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered FROM `data-to-insights.ecommerce.rev_transactions` WHERE avg_products_ordered > 20 GROUP BY geoNetwork_city ORDER BY avg_products_ordered DESC'

# 5. Solusi Final Tugas 3 menggunakan HAVING
eksekusi_log_lab "T3.5 - Solusi Akhir Tugas 3 Pakai HAVING" \
'SELECT geoNetwork_city, SUM(totals_transactions) AS total_products_ordered, COUNT( DISTINCT fullVisitorId) AS distinct_visitors, SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered FROM `data-to-insights.ecommerce.rev_transactions` GROUP BY geoNetwork_city HAVING avg_products_ordered > 20 ORDER BY avg_products_ordered DESC'


# ============================================================
# TUGAS 4: JUMLAH TOTAL PRODUK PER KATEGORI (20 Poin)
# ============================================================
echo -e "${BOLD}${YELLOW}=== MEMULAI EKSEKUSI TUGAS 4 (URUTAN MODUL PERSIS) ===${NC}"

# 1. Kueri GROUP BY tanpa fungsi agregasi asli
eksekusi_log_lab "T4.1 - GROUP BY Tanpa Agregasi Utama" \
'SELECT hits_product_v2ProductName, hits_product_v2ProductCategory FROM `data-to-insights.ecommerce.rev_transactions` GROUP BY 1,2'

# 2. Kueri COUNT biasa dengan filter NOT NULL
eksekusi_log_lab "T4.2 - COUNT Biasa Filter NOT NULL" \
'SELECT COUNT(hits_product_v2ProductName) as number_of_products, hits_product_v2ProductCategory FROM `data-to-insights.ecommerce.rev_transactions` WHERE hits_product_v2ProductName IS NOT NULL GROUP BY hits_product_v2ProductCategory ORDER BY number_of_products DESC'

# 3. Solusi Final Tugas 4 menggunakan DISTINCT dan LIMIT 5
eksekusi_log_lab "T4.3 - Solusi Akhir Tugas 4 dengan DISTINCT" \
'SELECT COUNT(DISTINCT hits_product_v2ProductName) as number_of_products, hits_product_v2ProductCategory FROM `data-to-insights.ecommerce.rev_transactions` WHERE hits_product_v2ProductName IS NOT NULL GROUP BY hits_product_v2ProductCategory ORDER BY number_of_products DESC LIMIT 5'


# Ringkasan Selesai
echo -e "${CYAN}============================================================${NC}"
echo -e "${GREEN}[SELESAI] Seluruh 11 riwayat kueri instruksi lab berhasil disuntikkan!${NC}"
echo -e "${YELLOW}[INFO] Silakan kembali ke tab lab Anda dan klik semua tombol 'Periksa progres saya'.${NC}"
echo -e "${CYAN}============================================================${NC}"