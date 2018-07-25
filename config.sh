#!/bin/sh

MYSQL_ROOT_PASSWORD=mypassword
MYSQL_REDMINE_PASSWORD=mypass

# mysql root reset password
service mysql start
service mysql stop
mysqld_safe --skip-grant-tables &
echo """
use mysql;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD');
flush privileges;
""" | mysql -u root
killall -9 mysqld_safe

# mysql redmine password
service mysql restart
echo """
CREATE DATABASE redmine CHARACTER SET utf8mb4;
CREATE USER 'redmine'@'localhost' IDENTIFIED BY '$MYSQL_REDMINE_PASSWORD';
GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';
""" | mysql -u root --password=$MYSQL_ROOT_PASSWORD

# redmine mysql configuration
cd /opt/redmine*
echo """
production:
  adapter: mysql2
  database: redmine
  host: localhost
  username: redmine
  password: $MYSQL_REDMINE_PASSWORD
  encoding: utf8
""" > config/database.yml

# apache configuration
cd /etc/apache2/sites-enabled
a2enmod proxy
a2enmod proxy_http
rm 000-default.conf
echo """
<VirtualHost *:80>
    ServerName server
    ServerAlias www.server
    ProxyPass / http://localhost:3000/
    ProxyPassReverse / http://localhost:3000/
</VirtualHost>
""" > redmine.conf 
