#!/bin/bash
# ==============================================================================
# Nama Skrip : belajar_task1_manual.sh
# Deskripsi  : Panduan Interaktif Manual Langkah Demi Langkah (Task 1)
# Pembuat    : Juanndnich & AI Collaborator
# ==============================================================================

# --- Konfigurasi Warna Terminal ---
NC='\033[0m'
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
BOLD='\033[1m'

# --- Fungsi Validasi Input Pengguna ---
tunggu_konfirmasi() {
    echo -ne "\n${YELLOW}[INPUT]${NC} Apakah Anda sudah menyelesaikan langkah ini dengan benar? (y/n): "
    read -r JAWABAN
    while [[ ! "$JAWABAN" =~ ^[Yy]$ ]]; do
        echo -e "${RED}[!] Harap selesaikan instruksi di atas terlebih dahulu di browser Anda.${NC}"
        echo -ne "Ketik '${BOLD}y${NC}' jika sudah selesai: "
        read -r JAWABAN
    done
    clear
    # Gambar ulang header setiap ganti langkah
    cetak_header
}

cetak_header() {
    echo -e "${CYAN}============================================================${NC}"
    printf "${YELLOW}%38s\n${NC}" "Fasttrack Key By Juanndnich"
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${BOLD}            MENTORING MANUAL TASK 1: DATA STUDIO            ${NC}"
    echo -e "${CYAN}============================================================${NC}\n"
}

# --- MULAI PROGRAM ---
clear
cetak_header

# --- LANGKAH 1 ---
echo -e "${BOLD}LANGKAH 1: Membuka Platform${NC}"
echo -e "1. Buka tab baru di browser Anda (disarankan Mode Incognito/Samaran)."
echo -e "2. Akses tautan berikut: ${CYAN}https://lookerstudio.google.com${NC}"
echo -e "3. Pastikan Anda login menggunakan ${RED}Username dan Password${NC} yang disediakan oleh panel Qwiklabs."
tunggu_konfirmasi

# --- LANGKAH 2 ---
echo -e "${BOLD}LANGKAH 2: Registrasi Awal Akun Lab${NC}"
echo -e "1. Di halaman utama Looker Studio, klik tombol ${BOLD}Blank Report${NC} (Laporan Kosong)."
echo -e "2. Jendela pop-up persetujuan akan muncul."
echo -e "   - Pilih ${CYAN}Country${NC} (Negara) bebas dan isi ${CYAN}Company${NC} (Perusahaan) sembarang."
echo -e "   - Centang kotak persetujuan Terms of Service, lalu klik ${GREEN}Continue${NC}."
echo -e "3. Pada dialog opsi email (Sign up for emails), pilih ${RED}No${NC} untuk semua pilihan."
echo -e "4. Klik tombol ${GREEN}Continue${NC}."
echo -e "5. Klik kembali tombol ${BOLD}Blank Report${NC} untuk kedua kalinya."
tunggu_konfirmasi

# --- LANGKAH 3 ---
echo -e "${BOLD}LANGKAH 3: Menghubungkan Konektor BigQuery${NC}"
echo -e "1. Saat ini Anda berada di tab ${BOLD}Connect to data${NC}."
echo -e "2. Cari bagian ${CYAN}Google Connectors${NC}, lalu klik dan pilih ${BOLD}BigQuery${NC}."
echo -e "3. Jendela otorisasi akan muncul. Klik tombol ${RED}Authorize${NC}."
echo -e "   *(Tindakan ini memberikan izin akses Looker Studio ke proyek Google Cloud Anda)*"
tunggu_konfirmasi

# --- LANGKAH 4 ---
echo -e "${BOLD}LANGKAH 4: Menentukan Sumber Data (Krusial)${NC}"
echo -e "Di panel menu navigasi, pilih opsi secara berurutan dari kiri ke kanan:"
echo -e "1. Klik menu menu paling kiri: ${BOLD}Shared projects${NC}"
echo -e "2. Pilih ${CYAN}Project ID Anda${NC} (yang berawalan dengan 'qwiklabs-gcp-')."
echo -e "3. Di kolom isian 'Shared project name', ketik persis: ${GREEN}data-to-insights${NC}"
echo -e "4. Pada kolom Dataset, pilih: ${GREEN}ecommerce${NC}"
echo -e "5. Pada kolom Table, pilih: ${GREEN}sales_report${NC}"
echo -e "6. Klik tombol ${BOLD}Add${NC} di sudut kanan bawah, lalu konfirmasi dengan klik ${BOLD}Add to report${NC}."
tunggu_konfirmasi

# --- LANGKAH 5 ---
echo -e "${BOLD}LANGKAH 5: Kustomisasi Tipe Data Visual (Akhir Task 1)${NC}"
echo -e "1. Klik menu atas: ${BOLD}Add a chart${NC} -> pilih ${BOLD}Table chart${NC} (Tabel default)."
echo -e "2. Di panel sebelah kanan (Data Field), cari kolom bernama ${CYAN}ratio${NC}."
echo -e "3. Klik dan seret (drag) kolom ${CYAN}ratio${NC} tersebut ke dalam bagian ${BOLD}Dimension${NC}."
echo -e "4. Klik ikon berbentuk angka/pensil di sebelah kiri tulisan 'ratio' untuk mengedit."
echo -e "5. Pada menu drop-down ${BOLD}Data type${NC}, ubah pengaturannya menjadi: ${GREEN}Numeric > Percent${NC}."
echo -e "6. Hapus tabel bawaan/acak yang dibuat otomatis sebelumnya agar kanvas bersih."
tunggu_konfirmasi

# --- SELESAI ---
echo -e "${GREEN}============================================================${NC}"
echo -e "${BOLD}                 SEMUA LANGKAH MANUAL SELESAI               ${NC}"
echo -e "${GREEN}============================================================${NC}"
echo -e "Sekarang, silakan kembali ke halaman instruksi Qwiklabs Anda"
echo -e "dan klik tombol ${BOLD}Check my progress${NC} pada Task 1."
echo -e "Sistem grading dipastikan akan memberikan poin penuh (berwarna hijau)."
echo -e "${GREEN}============================================================${NC}"