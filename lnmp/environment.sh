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
MEMCACHE_VERSION="memcache-2.2.7"
MEMCACHE_FILE_NAME="$MEMCACHE_VERSION.tgz"
PHP_MIRROR="http://cn2.php.net/"
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
sudo apt-get install unzip libpcre3 libpcre3-dev libssl-dev openssl libgd2-xpm-dev build-essential libncurses5-dev sysv-rc-conf cmake libxml2-dev libcurl4-openssl-dev libmcrypt4 libmcrypt-dev memcached libevent-dev autoconf

# add user
sudo groupadd www
sudo useradd -r -g www www
sudo groupadd mysql
sudo useradd -r -g mysql mysql

# install nginx
cd  $DATA_SOURCE_FILE_ROOT
wget http://nginx.org/download/$NGINX_FILE_NAME
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
VERSION_PREFIX=${MYSQL_VERSION:6:3}
wget http://dev.mysql.com/get/Downloads/MySQL-$VERSION_PREFIX/$MYSQL_FILE_NAME
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
ldconfig

# start mysql
/etc/init.d/mysqld start
exit
# install php
wget wget -c $PHP_MIRROR/distributions/$PHP_FILE_NAME
tar -xzvf $PHP_FILE_NAME
cd $PHP_VERSION
./configure --prefix="$PHP_PREFIX" --with-config-file-path="$PHP_PREFIX" --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql="$MYSQL_PREFIX" --with-mysqli="$MYSQL_PREFIX/bin/mysql_config" --with-pdo-mysql="$MYSQL_PREFIX" --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir= --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-gettext
sudo make && make install 

# copy php-fpm config & php.ini
cp "$PHP_PREFIX/etc/php-fpm.conf.default" "$PHP_PREFIX/etc/php-fpm.conf"
cp $DATA_SOURCE_FILE_ROOT/$PHP_VERSION/php.ini-production $PHP_PREFIX/lib/php.ini

# start memcached server
memcached -d -m 256 -p 11211 -u root -c 1024

# install php_memcache
#cd $DATA_SOURCE_FILE_ROOT
#wget http://pecl.php.net/get/$MEMCACHE_FILE_NAME
#tar -xzvf $MEMCACHE_FILE_NAME
#cd $MEMCACHE_VERSION
#$PHP_PREFIX/bin/phpize
#./configure --enable-memcache --with-php-config="$DATA_PHP_PREFIX/bin/php-config" --with-zlib-dir
#sudo make && make install

# start nginx & php-fpm
cd ~
sudo $NGINX_PREFIX/sbin/nginx
sudo $PHP_PREFIX/sbin/php-fpm
