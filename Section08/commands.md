We set up our project in the following way:
```
Section08/
├─ dockerfiles/
│  ├─ compose.dockerfile
│  └─ php.dockerfile
├─ env/
│  └─ mysql.env
├─ nginx/
│  └─ nginx.conf
├─ src/
└─ docker-compose.yml
```

`dockerfiles/php.dockerfile`:
```docker
FROM php:7.4-fpm-alpine
WORKDIR /var/www/html
RUN docker-php-ext-install pdo pdo_mysql
```
`dockerfiles/compose.dockerfile`:
```docker
FROM composer:latest
WORKDIR /var/www/html
ENTRYPOINT [ "composer", "--ignore-platform-reqs" ]
```
`env/mysql.env`:
```properties
MYSQL_DATABASE=homestead
MYSQL_USER=homestead
MYSQL_PASSWORD=secret
MYSQL_ROOT_PASSWORD=secret
```
`nginx/nginx.conf`:
```conf
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
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```
`docker-compose.yml`:
```yml
services:
  server:
    image: nginx:stable-alpine
    ports:
      - 8000:80
    volumes:
      - ./src:/var/www/html # The server will forward PHP files to the PHP interpreter (php service). So it needs access to those files.
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php
      - mysql
    
  php:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated # :delegated improves performance
    # ports:
      # - 3000:9000
      # php exposes port 9000. My app (see nginx.conf) expects port 3000.
      # But this port isn't needed. We talk directly to containers through the implicit network.
      # Just change fastcgi_pass php:3000; to fastcgi_pass php:9000; and we're done.
  
  mysql:
    image: mysql:5.7
    env_file:
      ./env/mysql.env
    
  composer:
    build:
      context: ./dockerfiles
      dockerfile: composer.dockerfile
    volumes:
      - ./src:/var/www/html
```

## Setup the Laravel application
Open a terminal.
```sh
docker-compose run --rm composer create-project --prefer-dist laravel/laravel .
```

Laravel will now generate code for us that will automatically be added to our `src` folder. Open the .env file inside the `src` folder, and find the database configuration.
```properties
DB_CONNECTION=sqlite
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=laravel
# DB_USERNAME=root
# DB_PASSWORD=
```
This should become:
```properties
DB_CONNECTION=mysql
DB_HOST=mysql         # name of the service in docker-compose.yml
DB_PORT=3306          # default for MySQL
DB_DATABASE=homestead # value of MYSQL_DATABASE in mysql.env
DB_USERNAME=homestead # value of MYSQL_USER in mysql.env
DB_PASSWORD=secret    # value of MYSQL_PASSWORD in mysql.env
```

We can now test the application. But we don't need to start the utility containers. We start a subset of the containers in the `docker-compose yml` configuration.
```sh
docker-compose up -d server
```
Now `docker ps` tells us that php, mysql and server are up and running.

Right now, if there's any change, it's not reflected in the Docker image. That's because we keep reusing the existing images.
We can fix that with:
```sh
docker-compose up -d --build server
```

## Setting up Artisan and NPM
```yml

  artisan:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html
  
  npm:
    image: node:14
    working_dir: /var/www/html
    entrypoint: [ "npm" ]
    volumes:
      - ./src:/var/www/html
```
We can now run a Artisan command. For example the `migrate`. This will write to the database.
```sh
docker-compose run --rm artisan migrate
```

## COPY vs Bind Mounts
We'r using bind mounds to make our source code available. But that's not useful during deployment.

So we make a new dockerfile to address this.

`dockerfiles/ginx.dockerfile`:
```docker
FROM nginx:stable-alpine
WORKDIR /etc/nginx/conf.d
COPY nginx.conf .
RUN mv nginx.conf default.conf
WORKDIR /var/www/html
COPY src .
```
No we need to change the `docker-compose.yml` file to use this new dockerfile.

```yml
service:
  server:
    # image: nginx:stable-alpine
    build:
      context: .
      dockerfile: dockerfiles/nginx.dockerfile
```

For the same reason, we change the php.dockerfile.
```docker
FROM php:8.1.0RC5-fpm-alpine3.14
WORKDIR /var/www/html
COPY src .
RUN docker-php-ext-install pdo pdo_mysql
RUN chown -R www-data:www-data /var/www/html
```
So in the docker-compose.yml` file we need to change the context:
```yml
  php:
    build:
      context: .
      dockerfile: dockerfiles/php.dockerfile
```