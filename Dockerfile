FROM mcr.microsoft.com/appsvc/php:7.4-apache_20220405.4

# Install PHP extensions
RUN apt-get --allow-releaseinfo-change update && apt-get install --no-install-recommends -y \
    ca-certificates \
    build-essential  \
    software-properties-common \
    cron \
    git \
    htop \
    wget \
    dos2unix \
    curl \
    libcurl4-gnutls-dev \
    sudo \
    libc-client-dev \
    libkrb5-dev \
    libmcrypt-dev \
    libssl-dev \
    libxml2-dev \
    libzip-dev \
    libjpeg-dev \
    libmagickwand-dev \
    libpng-dev \
    libgif-dev \
    libtiff-dev \
    libz-dev \
    libpq-dev \
    imagemagick \
    graphicsmagick \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libxpm-dev \
    libaprutil1-dev \
    libicu-dev \
    libfreetype6-dev \
    unzip \
    nano \
    zip \
    mariadb-client \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/cron.daily/*

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install imap && \
    docker-php-ext-enable imap

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/lib --with-png-dir=/usr/lib --with-jpeg-dir=/usr/lib \
    && docker-php-ext-install  gd \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install intl mbstring mysqli curl pdo_mysql zip opcache bcmath gd \
    && docker-php-ext-enable intl mbstring mysqli curl pdo_mysql zip opcache bcmath gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# By default disable cron jobs
ENV MAUTIC_RUN_CRON_JOBS false

# Setting an Default database user for Mysql
ENV MAUTIC_DB_USER root

# Setting an Default database name for Mysql
ENV MAUTIC_DB_NAME mautic

# Setting PHP properties
ENV PHP_INI_DATE_TIMEZONE='UTC' \
    PHP_MEMORY_LIMIT=512M \
    PHP_MAX_UPLOAD=512M \
    PHP_MAX_EXECUTION_TIME=300

# Download package and extract to web volume
RUN curl -o mautic.zip -SL https://github.com/FishAngler/mautic/releases/download/4.4.7.2/4.4.7.2.zip \
    && mkdir /usr/src/mautic \
    && unzip mautic.zip -d /usr/src/mautic \
    && rm mautic.zip \
    && chown -R www-data:www-data /usr/src/mautic

# Copy init scripts and custom .htaccess
COPY docker-entrypoint.sh /entrypoint.sh
COPY makeconfig.php makedb.php mautic.crontab /
RUN chmod 644 /mautic.crontab

# Enable Apache Rewrite Module
RUN a2enmod rewrite

# Apply necessary permissions
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]