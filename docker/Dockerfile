FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    git unzip libpq-dev curl libzip-dev libpng-dev libjpeg-dev \
    && docker-php-ext-install pdo pdo_pgsql pgsql zip mysqli \
    && a2enmod rewrite headers

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]