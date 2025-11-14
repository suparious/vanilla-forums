# Simplified Dockerfile for Vanilla Forums
# Single-stage build to reduce memory usage

FROM php:8.1-fpm-alpine

# Install system dependencies and PHP extensions required by Vanilla
RUN apk add --no-cache \
    curl-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        dom \
        fileinfo \
        gd \
        intl \
        mbstring \
        mysqli \
        pdo \
        pdo_mysql \
        xml \
        zip \
    && rm -rf /var/cache/apk/*

# Note: curl and json are built-in to PHP 8.1

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Create application directory
WORKDIR /var/www/html

# Copy application code
COPY . /var/www/html

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs || true

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
RUN rm -rf tests/ .git/ .github/ docker/ build/ .yarn/

# Switch to www-data user
USER www-data

# Expose PHP-FPM port
EXPOSE 9000

CMD ["php-fpm"]
