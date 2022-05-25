#!/bin/bash
green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}
sudo apt update && sudo apt upgrade -y && sudo apt install curl vim wget gnupg apt-transport-https lsb-release ca-certificates -y
sudo apt autoremove -y
#加入PHP最新版源
add-apt-repository ppa:ondrej/php
echo -ne '\n'
sudo apt update && sudo apt upgrade -y
#安装PHP8.1
apt install php8.1-fpm php8.1-cli php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-imap php8.1-opcache php8.1-soap php8.1-gmp php8.1-bcmath -y
#修改 php.ini 防止跨目录攻击
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.1/fpm/php.ini 
#增加上传大小限制
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/' /etc/php/8.1/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 10M/' /etc/php/8.1/fpm/php.ini
#增加 Apache 源
add-apt-repository ppa:ondrej/apache2
echo -ne '\n'
sudo apt update && sudo apt upgrade -y && sudo apt install apache2 -y
#green "Apache Version:"apache2 -v
sleep 5
a2enconf php8.1-fpm
a2enmod proxy_fcgi
a2enmod headers
a2enmod http2
a2enmod remoteip
a2enmod ssl
a2enmod rewrite
a2enmod expires
a2enmod deflate
a2enmod mime
a2enmod setenvif
systemctl restart php8.1-fpm
read -p "请输入网站名称（英文）:" domain
cat >> /etc/apache2/sites-available/$domain.conf << EOF
<VirtualHost *:80>
	ServerName $domain
	DocumentRoot /var/www/$domain
	DirectoryIndex index.php index.html index.htm
	
	ErrorLog ${APACHE_LOG_DIR}/$domain.error.log
	CustomLog ${APACHE_LOG_DIR}/$domain.access.log combined

	<Directory /var/www/$domain>
		Options FollowSymLinks
		AllowOverride All
		Require all granted
	</Directory>
</VirtualHost>
EOF
a2ensite $domain.conf
a2dissite 000-default.conf
apache2ctl configtest
systemctl restart apache2
mkdir -p /var/www/$domain
cat >> /var/www/$domain/phpinfo.php << EOF
<?php phpinfo(); ?>
EOF
wget -O /usr/share/keyrings/mariadb.asc https://mariadb.org/mariadb_release_signing_key.asc
echo "deb [signed-by=/usr/share/keyrings/mariadb.asc] https://mirror-cdn.xtom.com/mariadb/repo/10.6/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/mariadb.list
sudo apt update && sudo apt install mariadb-server  -y
systemctl enable mariadb