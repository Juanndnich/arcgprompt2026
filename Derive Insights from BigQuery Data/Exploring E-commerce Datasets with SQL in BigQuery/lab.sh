#!/usr/bin/env bash

# ============================================================
#         Fasttrack Key By Juanndnich
# ============================================================

# Mengaktifkan strict mode untuk keamanan eksekusi
set -euo pipefail

# Fungsi untuk menampilkan informasi status
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

# Fungsi untuk menampilkan pesan error
log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1"
}

# Membersihkan layar dan menampilkan logo kustom
clear
echo "============================================================"
printf "%38s\n" "Fasttrack Key By Juanndnich"
echo "============================================================"

log_info "Memulai eksekusi lengkap seluruh proses lab BigQuery E-commerce..."

# Validasi lingkungan: Memastikan bq CLI terinstal dan aktif
if ! command -v bq &> /dev/null; then
    log_error "Alat command line 'bq' tidak ditemukan. Pastikan Anda menjalankan script ini di Google Cloud Shell."
    exit 1
fi

# -------------------------------------------------------------------------
# PROSES 1: Pencarian Baris Duplikat (all_sessions_raw)
# -------------------------------------------------------------------------
log_info "Proses 1/5: Menjalankan kueri pencarian baris duplikat..."
bq query --use_legacy_sql=false \
'SELECT COUNT(*) as num_duplicate_rows, * FROM `data-to-insights.ecommerce.all_sessions_raw` GROUP BY fullVisitorId, channelGrouping, time, country, city, totalTransactionRevenue, transactions, timeOnSite, pageviews, sessionQualityDim, date, visitId, type, productRefundAmount, productQuantity, productPrice, productRevenue, productSKU, v2ProductName, v2ProductCategory, productVariant, currencyCode, itemQuantity, itemRevenue, transactionRevenue, transactionId, pageTitle, searchKeyword, pagePathLevel1, eCommerceAction_type, eCommerceAction_step, eCommerceAction_option HAVING num_duplicate_rows > 1'

echo "------------------------------------------------------------"

# -------------------------------------------------------------------------
# PROSES 2: Daftar Produk Unik Secara Alfabetis
# -------------------------------------------------------------------------
log_info "Proses 2/5: Menjalankan kueri unique product names secara alfabetis..."
bq query --use_legacy_sql=false \
'SELECT (v2ProductName) AS ProductName FROM `data-to-insights.ecommerce.all_sessions` GROUP BY ProductName ORDER BY ProductName'

echo "------------------------------------------------------------"

# -------------------------------------------------------------------------
# PROSES 3: 5 Produk dengan Tampilan Terbanyak (Product Views)
# -------------------------------------------------------------------------
log_info "Proses 3/5: Menjalankan kueri 5 produk teratas berdasarkan tampilan..."
bq query --use_legacy_sql=false \
'SELECT 
  COUNT(*) AS product_views,
  (v2ProductName) AS ProductName
 FROM `data-to-insights.ecommerce.all_sessions`
 WHERE type = "PAGE" 
 GROUP BY v2ProductName
 ORDER BY product_views DESC 
 LIMIT 5'

echo "------------------------------------------------------------"

# -------------------------------------------------------------------------
# PROSES 4: Refined Query (Menghindari Double-Count Tampilan per Pengunjung)
# -------------------------------------------------------------------------
log_info "Proses 4/5: Menjalankan refined query (unique view count per visitor)..."
bq query --use_legacy_sql=false \
'WITH unique_product_views_by_person AS (
  SELECT
    fullVisitorId,
    (v2ProductName) AS ProductName
  FROM `data-to-insights.ecommerce.all_sessions`
  WHERE type = "PAGE"
  GROUP BY fullVisitorId, v2ProductName
)
SELECT
  COUNT(*) AS unique_view_count,
  ProductName
FROM unique_product_views_by_person
GROUP BY ProductName
ORDER BY unique_view_count DESC
LIMIT 5'

echo "------------------------------------------------------------"

# -------------------------------------------------------------------------
# PROSES 5: Analisis Pesanan (Distinct Products Ordered & Total Units Ordered)
# -------------------------------------------------------------------------
log_info "Proses 5/5: Menjalankan kueri pesanan, jumlah orders, dan total unit ordered..."
bq query --use_legacy_sql=false \
'SELECT 
  COUNT(*) AS product_views,
  COUNT(productQuantity) AS orders,
  SUM(productQuantity) AS quantity_product_ordered,
  v2ProductName 
 FROM `data-to-insights.ecommerce.all_sessions`
 WHERE type = "PAGE" 
 GROUP BY v2ProductName
 ORDER BY product_views DESC 
 LIMIT 5'

echo "============================================================"
log_info "Seluruh proses rangkaian lab BigQuery telah sukses dieksekusi!"