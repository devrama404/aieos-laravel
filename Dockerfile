# Stage 1: Build dependency menggunakan Composer
FROM composer:2.7 AS build
WORKDIR /app
COPY . /app
# Menambahkan --ignore-platform-reqs agar composer tidak komplain tentang ekstensi PHP saat build stage
RUN composer install --no-dev --prefer-dist --no-scripts --no-progress --optimize-autoloader --ignore-platform-reqs

# Stage 2: Application Runtime
FROM php:8.2-fpm-alpine

# Install system dependencies & PHP extensions yang dibutuhkan Laravel/Aimeos
RUN apk add --no-cache \
    nginx \
    supervisor \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    zip \
    libzip-dev \
    unzip \
    icu-dev \
    oniguruma-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl \
    && docker-php-ext-enable opcache

# Setup working directory
WORKDIR /var/www/html

# Copy source code dari stage build
COPY --from=build --chown=www-data:www-data /app /var/www/html

# Copy konfigurasi custom Nginx dan Supervisor
COPY ./docker/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/supervisord.conf /etc/supervisord.conf

# Set permission untuk storage dan cache Laravel
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
