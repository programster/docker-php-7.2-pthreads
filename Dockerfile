FROM ubuntu:16.04

LABEL maintainer="sdpagent@gmail.com"

RUN apt-get update
RUN apt-get dist-upgrade -y

# Install the relevant packages
RUN apt-get install -y wget libzip-dev bison autoconf build-essential pkg-config git-core \
libltdl-dev libbz2-dev libxml2-dev libxslt1-dev libssl-dev libicu-dev \
libpspell-dev libenchant-dev libmcrypt-dev libpng-dev libjpeg8-dev \
libfreetype6-dev libmysqlclient-dev libreadline-dev libcurl4-openssl-dev

# Install pear for installing pthreads later.
RUN apt-get install php7.0-dev php-pear -y

# The previous command will have installed PHP, so remove it
RUN apt-get remove php-cli -y

WORKDIR /root
RUN wget https://github.com/php/php-src/archive/php-7.2.2.tar.gz

RUN tar --extract --gzip --file php-*
RUN rm php-*.tar.gz
RUN mv php-src-* php-src

WORKDIR /root/php-src
RUN ./buildconf --force

ENV CONFIGURE_STRING="--prefix=/etc/php7 \
--with-bz2 \
--with-zlib \
--enable-zip \
--disable-cgi \
--enable-soap \
--enable-intl \
--with-openssl \
--with-readline \
--with-curl \
--enable-ftp \
--enable-mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--enable-sockets \
--enable-pcntl \
--with-pspell \
--with-enchant \
--with-gettext \
--with-gd \
--enable-exif \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--with-xsl \
--enable-bcmath \
--enable-mbstring \
--enable-calendar \
--enable-simplexml \
--enable-json \
--enable-hash \
--enable-session \
--enable-xml \
--enable-wddx \
--enable-opcache \
--with-pcre-regex \
--with-config-file-path=/etc/php7/cli \
--with-config-file-scan-dir=/etc/php7/etc \
--enable-cli \
--enable-maintainer-zts \
--with-tsrm-pthreads \
--enable-debug \
--enable-fpm \
--with-fpm-user=www-data \
--with-fpm-group=www-data"

RUN ./configure $CONFIGURE_STRING

RUN make && make install

# Update the symlink for php to point to our custom build.
RUN rm /usr/bin/php
RUN ln -s /etc/php7/bin/php /usr/bin/php

# Install pthreads
RUN chmod o+x /etc/php7/bin/phpize
RUN chmod o+x /etc/php7/bin/php-config

RUN git clone https://github.com/krakjoe/pthreads.git

WORKDIR pthreads
RUN /etc/php7/bin/phpize

RUN ./configure \
--prefix='/etc/php7' \
--with-libdir='/lib/x86_64-linux-gnu' \
--enable-pthreads=shared \
--with-php-config='/etc/php7/bin/php-config'

RUN make && make install

# Set up our php ini 
RUN mkdir -p /etc/php7/cli/
RUN cp /root/php-src/php.ini-production /etc/php7/cli/php.ini

# Add the pthreads extension to the php.ini
RUN echo "extension=pthreads.so" | tee -a /etc/php7/cli/php.ini
RUN echo "zend_extension=opcache.so" | tee -a /etc/php7/cli/php.ini
