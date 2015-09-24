#!/bin/bash

# config
DATA_ROOT="/data"
DATA_DOWNLOAD="/data/download"
DATA_SOURCE_FILE_ROOT=$DATA_DOWNLOAD
DATA_SOURCE_FILE_NAME="lnmp.zip"
DATA_SOFTWARE_ROOT=$DATA_ROOT
LOG_ROOT="$DATA_ROOT/logs"

# nginx config
NGINX_VERSION="nginx-1.9.3"
NGINX_FILE_NAME="$NGINX_VERSION.tar.gz"
NGINX_PREFIX="$DATA_ROOT/nginx"

# mysql config
MYSQL_VERSION="mysql-5.5.41"
MYSQL_FILE_NAME="$MYSQL_VERSION.tar.gz"
MYSQL_PREFIX="$DATA_ROOT/mysql"

# php config
FREETYPE_VERSION="freetype-2.6"
FREETYPE_FILE_NAME="$FREETYPE_VERSION.tar.gz"
FREETYPE_PREFIX="$DATA_ROOT/freetype"
JPEG_VERSION="jpeg-9a"
JPEG_FILE_NAME="$JPEG_VERSION.tar.gz"
JPEG_PREFIX="$DATA_ROOT/jpeg"
LIBEVENT_VERSION="libevent-2.0.21-stable"
LIBEVENT_FILE_NAME="$LIBEVENT_VERSION.tar.gz"
LIBEVENT_PREFIX="$DATA_ROOT/libevent"
LIBPNG_VERSION="libpng-1.6.17"
LIBPNG_FILE_NAME="$LIBPNG_VERSION.tar.gz"
LIBPNG_PREFIX="$DATA_ROOT/libpng"
MEMCACHED_VERSION="memcached-1.4.24"
MEMCACHED_FILE_NAME="$MEMCACHED_VERSION.tar.gz"
MHASH_VERSION="mhash-0.9.9.9"
MHASH_FILE_NAME="$MHASH_VERSION.tar.gz"
PHP_VERSION="php-5.6.3"
PHP_FILE_NAME="$PHP_VERSION.tar.gz"
PHP_PREFIX="$DATA_ROOT/php"

# check if source file exists
if [ ! -d $DATA_SOURCE_FILE_ROOT ];then
	echo "source root not uploaded"
	exit
elif [ ! -f "$DATA_SOURCE_FILE_ROOT/$DATA_SOURCE_FILE_NAME" ];then
	echo "source file not exist"
	exit
fi

# update & upgrade os
sudo apt-get update
sudo apt-get upgrade

# install indepence
sudo apt-get install unzip
sudo apt-get install libpcre3 libpcre3-dev libssl-dev openssl libgd2-xpm-dev
sudo apt-get install build-essential  
sudo apt-get install libncurses5-dev  
sudo apt-get install sysv-rc-conf  
sudo apt-get install cmake 
sudo apt-get install libxml2-dev
sudo apt-get install libcurl4-openssl-dev
sudo apt-get install libmcrypt4
sudo apt-get install libmcrypt-dev

# unzip lnmp source file
cd $DATA_SOURCE_FILE_ROOT
sudo unzip $DATA_SOURCE_FILE_NAME

# add user
sudo groupadd www
sudo useradd -r -g www www
sudo groupadd mysql
sudo useradd -r -g mysql mysql

# install nginx
cd  $DATA_SOURCE_FILE_ROOT
tar -xzvf $NGINX_FILE_NAME
cd $NGINX_VERSION
./configure --prefix="$NGINX_PREFIX" --with-http_ssl_module --with-http_image_filter_module --with-http_stub_status_module
sudo make && make install

# create nginx log
if [ ! -d $LOG_ROOT ];then
        mkdir $LOG_ROOT
fi 
touch "$LOG_ROOT/nginx_error.log"
touch "$LOG_ROOT/nginx_access.log"

# replace nginx conf file
cp "$DATA_SOURCE_FILE_ROOT/nginx.conf" "$NGINX_PREFIX/conf"
cp -r "$DATA_SOURCE_FILE_ROOT/vhost" "$NGINX_PREFIX/vhost"
cp -r "$DATA_SOURCE_FILE_ROOT/conf.d" "$NGINX_PREFIX/conf/conf.d"

# install mysql
cd $DATA_SOURCE_FILE_ROOT
tar -xzvf $MYSQL_FILE_NAME
cd $MYSQL_VERSION
cmake -DCMAKE_INSTALL_PREFIX="$MYSQL_PREFIX" -DMYSQL_DATADIR="$MYSQL_PREFIX/data" -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWTIH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DENABLED_LOCAL_INFILE=1 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DEXTRA_CHARSETS=all -DMYSQL_TCP_PORT=3306
sudo make && make install  

# init mysql
cd $MYSQL_PREFIX
sudo mkdir -p "$MYSQL_PREFIX/data"
sudo mkdir -p "$MYSQL_PREFIX/log"
sudo chown -R mysql:mysql $MYSQL_PREFIX
sudo chmod -R 755 $MYSQL_PREFIX
sudo cp "$MYSQL_PREFIX/support-files/my-medium.cnf"  /etc/mysql.cnf
sudo "$MYSQL_PREFIX/scripts/mysql_install_db" --user=mysql --basedir="$MYSQL_PREFIX" --datadir="$MYSQL_PREFIX/data"

# copy mysql.server
sudo cp "$MYSQL_PREFIX/support-files/mysql.server" /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld

# create links
cd /usr/local/bin
ln -s $MYSQL_PREFIX/bin/mysql mysql &&
ln -s $MYSQL_PREFIX/bin/mysqldump mysqldump &&
ln -s $MYSQL_PREFIX/bin/mysqladmin mysqladmin

# change ld.so.conf
echo "$MYSQL_PREFIX/lib" >> /etc/ld.so.conf

# start mysql
/etc/init.d/mysqld start

# install php
cd $DATA_SOURCE_FILE_ROOT
tar -xzvf $PHP_FILE_NAME
cd $PHP_VERSION
./configure --prefix="$PHP_PREFIX" --with-config-file-path="$PHP_PREFIX" --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql="$MYSQL_PREFIX" --with-mysqli="$MYSQL_PREFIX/bin/mysql_config" --with-pdo-mysql="$MYSQL_PREFIX" --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir= --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-gettext
sudo make && make install 

# copy php-fpm config
cp "$PHP_PREFIX/etc/php-fpm.conf.default" "$PHP_PREFIX/etc/php-fpm.conf"

# start nginx & php-fpm
cd ~
sudo $NGINX_PREFIX/sbin/nginx
sudo $PHP_PREFIX/sbin/php-fpm
