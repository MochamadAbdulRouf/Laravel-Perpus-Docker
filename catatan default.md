File `default.conf` ini adalah konfigurasi **Nginx** yang dipakai untuk service `nginx` di `docker-compose.yml`. Aku rapikan dulu, lalu jelaskan per baris.

---

### Kode `default.conf` yang sudah dirapikan

```nginx
server {
    listen 80;
    index index.php index.html;
    server_name localhost;
    root /var/www/html/public;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

---

### Penjelasan tiap bagian

#### **Blok `server { ... }`**

* Mendefinisikan satu **virtual host** untuk menangani request web.

---

#### **`listen 80;`**

* Nginx akan menerima koneksi HTTP di **port 80**.
* Karena di `docker-compose.yml`, port container ini di-mapping ke `8000:80`, maka akses dari host adalah `http://localhost:8000`.

---

#### **`index index.php index.html;`**

* File default yang dicari ketika user akses root folder (`/`).
* Urutannya: `index.php` → `index.html`.

---

#### **`server_name localhost;`**

* Mendefinisikan nama server (hostname).
* Di sini menggunakan `localhost`.
* Bisa diganti dengan domain kalau dipakai di server beneran.

---

#### **`root /var/www/html/public;`**

* Menentukan folder root untuk aplikasi.
* Laravel butuh diarahkan ke `public/` karena di situlah `index.php` (entrypoint aplikasi Laravel) berada.

---

### 🔹 Blok `location / { ... }`

```nginx
location / {
    try_files $uri $uri/ /index.php?$query_string;
}
```

* Mengatur cara menangani request untuk semua URL.
* `try_files $uri $uri/ /index.php?$query_string;` artinya:

  1. Kalau file statis sesuai `$uri` ada → tampilkan.
  2. Kalau folder sesuai `$uri/` ada → tampilkan.
  3. Kalau tidak ada → teruskan request ke `index.php` Laravel + query string (`?$query_string`).

➡️ Dengan ini semua route Laravel (`/login`, `/dashboard`, dll) akan diarahkan ke `index.php`.

---

### 🔹 Blok `location ~ \.php$ { ... }`

```nginx
location ~ \.php$ {
    try_files $uri =404;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass app:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
}
```

* Dipakai untuk request file PHP.

* **`try_files $uri =404;`**

  * Cek apakah file PHP ada.
  * Kalau tidak ada → return 404.

* **`fastcgi_split_path_info ^(.+\.php)(/.+)$;`**

  * Memisahkan path file PHP dengan path info tambahan.
  * Misal: `/index.php/something` → dipisah jadi `index.php` dan `/something`.

* **`fastcgi_pass app:9000;`**

  * Meneruskan request PHP ke container `app` (Laravel/PHP-FPM) pada **port 9000**.
  * Nama `app` sesuai service di `docker-compose.yml`.

* **`fastcgi_index index.php;`**

  * File PHP default kalau hanya folder yang diakses.

* **`include fastcgi_params;`**

  * Include default parameter FastCGI bawaan Nginx.

* **`fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;`**

  * Mengirimkan path lengkap file PHP ke PHP-FPM.

* **`fastcgi_param PATH_INFO $fastcgi_path_info;`**

  * Mengirimkan informasi tambahan setelah nama file PHP.

---

## 🔗 Hubungan dengan File Lain

* **`docker-compose.yml`**

  * Nginx pakai file ini (`./docker/nginx/default.conf`) sebagai konfigurasi.
  * Port `8000` di-host diarahkan ke `80` di-container.

* **`Dockerfile` + `entrypoint.sh`**

  * Nginx tidak langsung eksekusi PHP.
  * Dia meneruskan request PHP ke service `app` (`php-fpm` yang dijalankan oleh `entrypoint.sh`).

➡️ Jadi flow request-nya:
`User (http://localhost:8000)` → `Nginx` (default.conf) → `PHP-FPM (app:9000)` → `Laravel` → `MySQL (db)`

---

Mau aku bikinkan **diagram alur request** (visual) supaya lebih gampang memahami hubungan `default.conf` dengan file lain?
