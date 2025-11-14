# Multi-stage Dockerfile for Vanilla Forums
# Stage 1: Build frontend assets with Node/Yarn
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Install dependencies
RUN yarn install --immutable

# Copy source code
COPY . .

# Build frontend assets
RUN yarn run build

# Stage 2: PHP application image
FROM php:8.1-fpm-alpine

# Install PHP extensions required by Vanilla
RUN apk add --no-cache \
    curl \
    libxml2-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        curl \
        dom \
        fileinfo \
        gd \
        intl \
        json \
        mbstring \
        mysqli \
        pdo \
        pdo_mysql \
        xml \
        zip \
    && rm -rf /var/cache/apk/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Create application directory
WORKDIR /var/www/html

# Copy built frontend assets from builder
COPY --from=builder /app /var/www/html

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Create necessary directories
RUN mkdir -p /var/www/html/uploads \
    /var/www/html/cache \
    /var/www/html/conf \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/uploads \
    && chmod -R 777 /var/www/html/cache \
    && chmod -R 777 /var/www/html/conf

# Security: Remove development files
RUN rm -rf tests/ .git/ .github/ docker/

# Switch to www-data user
USER www-data

# Expose PHP-FPM port
EXPOSE 9000

CMD ["php-fpm"]
