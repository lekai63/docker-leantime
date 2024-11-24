FROM docker.io/library/php:8.3-fpm-alpine

# Build with: `docker build . --tag leantime:devel`

##########################
#### ENVIRONMENT INFO ####
##########################

# Change version to trigger build
ARG LEAN_VERSION=3.3.2

ARG PROJECT_OVERVIEW_VERSION=2.1.5

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
    --strip-components 1 && \
    sed -i '/premium/d' ./app/Domain/Menu/Repositories/Menu.php

RUN curl -L -o project-overview.tar.gz https://github.com/ITK-Leantime/project-overview/releases/download/${PROJECT_OVERVIEW_VERSION}/ProjectOverview-${PROJECT_OVERVIEW_VERSION}.tar.gz && \
    tar -xf project-overview.tar.gz && \
    rm project-overview.tar.gz && \
    sed -i 's/ticket.status <> '\''0'\''/ticket.status > '\''1'\''/' ./ProjectOverview/Repositories/ProjectOverview.php && \
    sed -i "s/'personal'/'company'/g" ./ProjectOverview/register.php

#  上面的命令解释：ticket.status <> '0' 调整为 ticket.status > '1'，因为“已归档”是-1，已完成是 0，“已取消”（block）是 1
# 'personal' 改为'company' 是为了把菜单放在“公司”选项卡下
# project-overview.tar.gz 根本不是gzip格式,不使用-z参数

# 放入自己增补的汉化文件


COPY ./code_modify/ProjectOverview/zh-CN.ini ./app/Plugins/ProjectOverview/Language/zh-CN.ini

COPY ./code_modify/zh-CN.ini ./app/Language/zh-CN.ini


COPY ./logo/* ./public/dist/images/

RUN mkdir -p /var/log/php-fpm && \
    chown -R www-data:www-data /var/log/php-fpm && chown www-data:www-data -R .

COPY ./start.sh /start.sh
RUN chmod +x /start.sh

COPY ./config_modify/custom.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY ./config_modify/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY ./config_modify/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
