FROM php:8.4-cli

WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libcurl4-openssl-dev \
    pkg-config \
    libssl-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install MongoDB extension
RUN pecl install mongodb && docker-php-ext-enable mongodb

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 1. Copy dependency definitions
COPY composer.json composer.lock ./

# 2. Install dependencies (without scripts and without autoloader first)
# This leverages Docker cache: if composer.json hasn't changed, this step is cached.
RUN composer install --no-interaction --no-scripts --no-autoloader

# 3. Copy application code
COPY . .

# 4. Generate autoloader and run scripts
RUN composer dump-autoload --optimize && \
    php artisan package:discover --ansi

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose the port
EXPOSE 8001

# Start the server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8001"]
