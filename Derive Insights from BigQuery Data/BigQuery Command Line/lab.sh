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

log_info "Memulai otomatisasi lab BigQuery (Tugas 2 dilewati)..."

# Validasi lingkungan: Memastikan bq CLI terinstal dan aktif
if ! command -v bq &> /dev/null; then
    log_error "Alat command line 'bq' tidak ditemukan. Pastikan Anda menjalankan script ini di Google Cloud Shell."
    exit 1
fi

# -------------------------------------------------------------------------
# Tugas 1: Menguji Tabel Shakespeare
# -------------------------------------------------------------------------
log_info "Tugas 1: Menampilkan skema tabel Shakespeare..."
bq show bigquery-public-data:samples.shakespeare

# -------------------------------------------------------------------------
# Tugas 3: Menjalankan Kueri pada Tabel Publik
# -------------------------------------------------------------------------
log_info "Tugas 3: Menjalankan kueri untuk mencari substring 'raisin'..."
bq query --use_legacy_sql=false \
'SELECT
   word,
   SUM(word_count) AS count
 FROM
   `bigquery-public-data`.samples.shakespeare
 WHERE
   word LIKE "%raisin%"
 GROUP BY
   word'

log_info "Menjalankan kueri pencarian kata 'huzzah' (diperkirakan tidak ada hasil)..."
bq query --use_legacy_sql=false \
'SELECT
   word
 FROM
   `bigquery-public-data`.samples.shakespeare
 WHERE
   word = "huzzah"' || true

# -------------------------------------------------------------------------
# Tugas 4: Membuat Tabel Baru & Mengupload Dataset
# -------------------------------------------------------------------------
log_info "Tugas 4: Memeriksa dan membuat dataset 'babynames'..."
if ! bq ls | grep -q "babynames"; then
    bq mk babynames
    log_info "Dataset 'babynames' berhasil dibuat."
else
    log_info "Dataset 'babynames' sudah ada, melewati pembuatan dataset."
fi

log_info "Memastikan file sumber data nama bayi tersedia..."
if [ ! -f "yob2010.txt" ]; then
    if [ ! -f "names.zip" ]; then
        if command -v wget &> /dev/null; then
            log_info "Mengunduh file menggunakan wget..."
            wget -q http://www.ssa.gov/OACT/babynames/names.zip
        elif command -v curl &> /dev/null; then
            log_info "Mengunduh file menggunakan curl..."
            curl -sO http://www.ssa.gov/OACT/babynames/names.zip
        else
            log_error "Perintah wget atau curl tidak tersedia untuk mengunduh data."
            exit 1
        fi
    fi
    log_info "Mengekstrak file names.zip..."
    unzip -o names.zip
else
    log_info "File sumber 'yob2010.txt' sudah tersedia di direktori."
fi

log_info "Memuat file sumber ke tabel 'names2010' di dalam dataset 'babynames'..."
if ! bq ls babynames | grep -q "names2010"; then
    bq load babynames.names2010 yob2010.txt name:string,gender:string,count:integer
    log_info "Tabel names2010 berhasil dimuat."
else
    log_info "Tabel names2010 sudah ada di dalam dataset, melewati proses load."
fi

log_info "Memeriksa tabel yang ada di dalam dataset babynames..."
bq ls babynames
bq show babynames.names2010

# -------------------------------------------------------------------------
# Tugas 5: Menjalankan Kueri pada Dataset Kustom
# -------------------------------------------------------------------------
log_info "Tugas 5: Menampilkan 5 nama anak perempuan terpopuler..."
bq query --use_legacy_sql=false "SELECT name,count FROM babynames.names2010 WHERE gender = 'F' ORDER BY count DESC LIMIT 5"

log_info "Menampilkan 5 nama anak laki-laki yang paling tidak umum..."
bq query --use_legacy_sql=false "SELECT name,count FROM babynames.names2010 WHERE gender = 'M' ORDER BY count ASC LIMIT 5"

# -------------------------------------------------------------------------
# Tugas 7: Membersihkan Dataset (Opsional)
# -------------------------------------------------------------------------
read -rp "tolong centang dulu semua progres kecuali yang bagian remove atau hapus itu nanti setelah semua di cek jalankan script ini, Apakah Anda ingin menghapus dataset 'babynames' untuk pembersihan akhir lab? (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    log_info "Menghapus dataset 'babynames' dan seluruh tabel di dalamnya..."
    bq rm -r -f babynames
    log_info "Dataset berhasil dibersihkan."
else
    log_info "Pembersihan dataset dilewati sesuai pilihan Anda."
fi

log_info "Semua rangkaian perintah tugas lab BigQuery selesai dijalankan dengan sukses!, mohon tunggu 1 - 3 menit untuk mendapatkan hasil optimal!!"