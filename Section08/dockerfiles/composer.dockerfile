FROM composer:2.9
WORKDIR /var/www/html
ENTRYPOINT [ "composer", "--ignore-platform-reqs" ]
