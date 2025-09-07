#!/bin/bash
# Menandakan bahwa script ini dijalankan menggunakan Bash shell.

# jalankan 'composer update' untuk mengatasi masalah lock file yang tidak kompatibel
echo "Running composer update..."
# Menjalankan composer update agar dependency Laravel sesuai dengan composer.json.
# --no-interaction → Tidak ada input manual.
# --no-scripts → Composer tidak menjalankan script tambahan.
composer update --no-interaction --no-scripts

# salin file .env jika belum ada
# kalau belum ada, buat dari template .env.example.Penting untuk environment Laravel (database, key, dll).
if [ ! -f .env ]; then
  echo "Creating .env file..."
  cp .env.example .env
fi 

# Generate Kunci aplikasi laravel 
# Membuat APP_KEY baru di .env.
# APP_KEY dipakai Laravel untuk enkripsi session, cookie, dsb.
echo "Generating application key..."
php artisan key:generate 

# TAMBAHKAN BARIS INI untuk membersihkan cache konfigurasi
echo "Clearing configuration cache..."
php artisan config:clear

# Tunggu Hingga Database siap
# Script looping sampai MySQL (service db) siap menerima koneksi.
# Gunakan env DB_USERNAME dan DB_PASSWORD dari docker-compose.yml.
echo "Waiting for database..."
while ! mysqladmin ping -h"db" -u"${DB_USERNAME}" -p"${DB_PASSWORD}" --silent; do
  sleep 1
done 

# jalankan migrasi dan seeder setelah database siap
# migrate → Membuat tabel sesuai migration Laravel.
# db:seed → Mengisi data awal ke database.
# --force → Jalankan tanpa konfirmasi (penting di container/CI/CD).
echo "Database is ready. Running migrations and seeding..."
php artisan migrate --force
php artisan db:seed --force

# Atur izin tulis untuk direktori storage dan boostrap/cache laravel
# Mengatur izin agar user www-data (user default PHP-FPM) bisa menulis ke folder storage dan bootstrap/cache.
# Wajib agar Laravel bisa menyimpan log, cache, dan session.
echo "Setting permissions for storage and bootstrap/cache..."
chown -R www-data:www-data storage bootstrap/cache

# Jalankan proses utama PHP-FPM
# Menjalankan proses utama container.
# Container tetap hidup selama proses PHP-FPM berjalan.
# Nginx nanti akan meneruskan request ke PHP-FPM (port 9000).
echo "starting PHP-FPM..."
php-fpm