#!/bin/bash
green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}
sudo apt update && sudo apt upgrade -y && sudo apt install curl vim wget gnupg apt-transport-https lsb-release ca-certificates socat -y
sudo apt autoremove -y
#加入PHP最新版源
add-apt-repository ppa:ondrej/php
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
sudo apt update && sudo apt upgrade -y && sudo apt install apache2 -y
#green "Apache Version:"apache2 -v
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
mkdir -p /var/www/ssl
systemctl stop apache2
read -p "请输入网站名称（英文）:" domain
    curl https://get.acme.sh | sh
    ln -s  /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
    acme.sh --set-default-ca --server letsencrypt
    green "已输入的域名：$domain"
    realip=$(curl -sm8 ip.sb)
    domainIP=$(curl -sm8 ipget.net/?ip="$domain")
    if [ $realip  ==  $domainIP ]
    then
        echo '域名解析OK' && sleep 3;
        bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256;
        bash ~/.acme.sh/acme.sh --install-cert -d ${domain} --key-file /var/www/ssl/$domain.key --fullchain-file /var/www/ssl/$domain.crt --ecc;
        green "证书申请成功！脚本申请到的证书（cert.crt）和私钥（private.key）已保存到 /var/www/ssl 文件夹";
    else
        echo '请检查域名是否已解析到该VPS' && sleep 3;
        
    fi
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
<VirtualHost *:443> 
    	ServerName  $domain                    
    	DocumentRoot  /var/www/$domain
	ErrorLog "/var/www/$domain/log/error.log"
	CustomLog "/var/www/$domain/log/access.log" combined        
   	SSLEngine on   
    	SSLProtocol all -SSLv2 -SSLv3
    	SSLCipherSuite HIGH:!RC4:!MD5:!aNULL:!eNULL:!NULL:!DH:!EDH:!EXP:+MEDIUM
   	SSLHonorCipherOrder on
   	SSLCertificateFile /var/www/ssl/$domain.crt
   	SSLCertificateKeyFile /var/www/ssl/$domain.key
	<FilesMatch "\.(cgi|shtml|phtml|php)$">
		SSLOptions +StdEnvVars
	</FilesMatch>
	<Directory /usr/lib/cgi-bin>
		SSLOptions +StdEnvVars
	</Directory>
</VirtualHost>
EOF
a2ensite $domain.conf
a2dissite 000-default.conf
apache2ctl configtest
systemctl restart apache2
mkdir -p /var/www/$domain
cat >> /var/www/$domain/index.html << EOF
<html>
	<h2>It works</h2>
</html>
EOF
cat >> /var/www/$domain/phpinfo.php << EOF
<?php phpinfo(); ?>
EOF
wget -O /usr/share/keyrings/mariadb.asc https://mariadb.org/mariadb_release_signing_key.asc
echo "deb [signed-by=/usr/share/keyrings/mariadb.asc] https://mirror-cdn.xtom.com/mariadb/repo/10.6/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/mariadb.list
sudo apt update && sudo apt install mariadb-server  -y
systemctl enable mariadb