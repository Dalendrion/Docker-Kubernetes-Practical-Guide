FROM php:8.1.0RC5-fpm-alpine3.14
WORKDIR /var/www/html
RUN docker-php-ext-install pdo pdo_mysql
