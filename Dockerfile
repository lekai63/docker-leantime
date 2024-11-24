# 构建阶段
FROM php:8.3-fpm-alpine AS builder

# 安装编译依赖
RUN apk add --no-cache \
    openldap-dev \
    libzip-dev \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    oniguruma-dev

# 编译PHP扩展
RUN docker-php-ext-install mysqli pdo_mysql mbstring exif pcntl pdo bcmath opcache ldap zip && \
    docker-php-ext-enable zip && \
    docker-php-ext-configure gd --enable-gd --with-jpeg=/usr/include/ --with-freetype --with-jpeg && \
    docker-php-ext-install gd

# 最终镜像
FROM php:8.3-fpm-alpine

ARG LEAN_VERSION=3.3.2
ARG PROJECT_OVERVIEW_VERSION=2.1.5

WORKDIR /var/www/html

# 复制编译好的扩展
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions

# 安装运行时依赖
RUN apk add --no-cache \
    mysql-client \
    zip \
    freetype \
    libpng \
    libjpeg-turbo \
    icu-libs \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    supervisor \
    && rm -rf /var/cache/apk/*

# 安装Leantime
RUN curl -sL https://github.com/Leantime/leantime/releases/download/v${LEAN_VERSION}/Leantime-v${LEAN_VERSION}.tar.gz | \
    tar --ungzip --extract --strip-components 1 && \
    sed -i '/premium/d' ./app/Domain/Menu/Repositories/Menu.php && \
    curl -L -o project-overview.tar.gz https://github.com/ITK-Leantime/project-overview/releases/download/${PROJECT_OVERVIEW_VERSION}/ProjectOverview-${PROJECT_OVERVIEW_VERSION}.tar.gz && \
    tar -xf project-overview.tar.gz && \
    rm project-overview.tar.gz && \
    sed -i 's/ticket.status <> '\''0'\''/ticket.status > '\''1'\''/' ./ProjectOverview/Repositories/ProjectOverview.php && \
    sed -i "s/'personal'/'company'/g" ./ProjectOverview/register.php && \
    sed -i 's#use Leantime\\Core\\Template;#use Leantime\\Core\\UI\\Template;#' ./ProjectOverview/Controllers/ProjectOverview.php && \
    mv ./ProjectOverview ./app/Plugins/ProjectOverview

# 复制资源文件
COPY ./ProjectOverview/dist/css/project-overview.css ./public/dist/css/
COPY ./ProjectOverview/dist/js/project-overview.js ./public/dist/js/
COPY ./code_modify/ProjectOverview/zh-CN.ini ./app/Plugins/ProjectOverview/Language/
COPY ./code_modify/zh-CN.ini ./app/Language/
COPY ./logo/* ./public/dist/images/
COPY ./start.sh /start.sh
COPY ./config_modify/custom.ini /usr/local/etc/php/conf.d/
COPY ./config_modify/supervisord.conf /etc/supervisor/conf.d/
COPY ./config_modify/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

RUN mkdir -p /var/log/php-fpm && \
    chown -R www-data:www-data /var/log/php-fpm && \
    chown www-data:www-data -R . && \
    chmod +x /start.sh

EXPOSE 80
ENTRYPOINT ["/start.sh"]