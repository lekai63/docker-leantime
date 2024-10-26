FROM docker.io/library/php:8.3-fpm-alpine

# Build with: `docker build . --tag leantime:devel`

##########################
#### ENVIRONMENT INFO ####
##########################

# Change version to trigger build
ARG LEAN_VERSION=3.2.1

WORKDIR /var/www/html

ENTRYPOINT ["/start.sh"]
EXPOSE 80

########################
#### IMPLEMENTATION ####
########################

# Install dependencies
RUN apk add --no-cache \
    mysql-client \
    openldap-dev\
    libzip-dev \
    zip \
    freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev oniguruma-dev \
    icu-libs \
    jpegoptim optipng pngquant gifsicle \
    supervisor


## Installing extensions ##
# Running in a single command is worse for caching/build failures, but far better for image size
RUN docker-php-ext-install \
    mysqli pdo_mysql mbstring exif pcntl pdo bcmath opcache ldap zip \
    && \
    docker-php-ext-enable zip \
    && \
    docker-php-ext-configure gd \
    --enable-gd \
    --with-jpeg=/usr/include/ \
    --with-freetype \
    --with-jpeg \
    && \
    docker-php-ext-install gd


## Installing Leantime ##

# (silently) Download the specified release, piping output directly to `tar`
RUN curl -sL https://github.com/Leantime/leantime/releases/download/v${LEAN_VERSION}/Leantime-v${LEAN_VERSION}.tar.gz | \
    tar \
    --ungzip \
    --extract \
    --verbose \
    --strip-components 1

RUN chown www-data:www-data -R .

COPY ./start.sh /start.sh
RUN chmod +x /start.sh

COPY config/custom.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
