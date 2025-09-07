# Gunakan base image PHP 7.2-fpm
# menggunakan base image resmi PHP versi 7.2 dengan FPM (FastCGI Process Manager)
# FPM dipakai karena laravel biasanya dijalankan bersama nginx (bukan apache)
FROM php:7.2-fpm 

# set working directory didalam container
# menentukan direktori kerja didalam container
# semua perintah setelah ini akan dijalanankan di folder /var/www/html
WORKDIR /var/www/html

# PERBAIKAN: Arahkan ke repository arsip untuk Debian 10 (Buster) yang sudah EOL
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list

# Install dependecies sistem & ektensi PHP yang dibutuhkan laravel
# Update daftar paket dan install dependecies sistem + libary yang dibutuhkan laravel
RUN apt-get update && apt-get install -y \
    # Untuk clone repo & request HTTP.
    git \ 
    curl \
    # Diperlukan untuk mbstring (multibyte string).
    libonig-dev \
    # Dibutuhkan untuk parsing XML.
    libxml2-dev \
    # Untuk kompresi ZIP (fitur Laravel & Composer).
    zip \
    unzip\
    libzip-dev \
    # Untuk manipulasi gambar (fitur GD di Laravel).
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    # Untuk koneksi MySQL dari dalam container.
    default-mysql-client \
 #Install ekstensi PHP yang penting untuk Laravel:
 && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip 

# install composer (dari official composer image)
# mengambil file composer dari image resmi composer:latest.
# menyalinnya ke dalam container di /usr/bin/composer.
# supaya composer bisa di pakai langsung tanpa install manual.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# konfigurasi Git agar tidak error "dubious ownership"
# mengatasi error "dubious ownership" saat menjalankan perintah git di dalam container sedang build
# error ini muncul kalau project laravel hasil mount di anggap tidak aman oleh git
RUN git config --global --add safe.directory /var/www/html

# copy souce code aplikasi ke dalam container
# menyalin semua source code project dari host kedalam container ( /var/www/html ).
COPY . .

# copy startup script & beri izin eksekusi 
# menyalin script startup (entrypoint.sh) ke folder /usr/local/bin di dalam container
COPY entrypoint.sh /usr/local/bin
# memberikan izin eksekusi pada file entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# set entrypoint ke startup script 
# menetukan bahwa container akan menjalankan script entrypoint.sh saat start
ENTRYPOINT [ "entrypoint.sh" ]


# expose port untuk PHP-FPM
# membuka port 9000 untk PHP-FPM
# nginx akan meneruskan request ke port ini
EXPOSE 9000

# Jadi alurnya:
# Container ini hanya menjalankan Laravel (PHP-FPM).
# Web server Nginx di docker-compose.yml bertugas meneruskan request ke PHP-FPM (port 9000).
