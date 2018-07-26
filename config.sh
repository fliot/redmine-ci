#!/bin/sh

export MYSQL_ROOT_PASSWORD=mypassword
export MYSQL_REDMINE_PASSWORD=mypass
export REDMINE_LANG=fr

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

if [ -d "/data/mysql/redmine" ]; then
    #######################################################################################
    # if the redmine database already exist, let'keep the local data
    #######################################################################################
    echo "################################################################################"
    echo "# redmine database ALREADY exist ###############################################"
    echo "################################################################################"
    
    service mysql start
    cd /opt/redmine
    gem install bundler
    bundle install --without development test
    rake redmine:plugins:migrate
    service mysql stop
    exit 0

else
    #######################################################################################
    # if the redmine database doesn't exist, let's initialize completly redmine
    #######################################################################################
    echo "################################################################################"
    echo "# redmine database and volume will be initialized ##############################"
    echo "################################################################################"

    # prepare volumes
    mkdir /data
    mv /var/lib/mysql                         /data/mysql
    sed -i 's!/var/lib/mysql!/data/mysql!g' /etc/mysql/mysql.conf.d/mysqld.cnf
    mv /opt/redmine/public/plugin_assets      /data/redmine_public_plugin_assets
    ln -s /data/redmine_public_plugin_assets  /opt/redmine/public/plugin_assets
    mv /opt/redmine/files                     /data/redmine_files
    ln -s /data/redmine_files                 /opt/redmine/files
    
    # mysql root reset password
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
    cd /opt/redmine
    echo """
production:
  adapter: mysql2
  database: redmine
  host: localhost
  username: redmine
  password: $MYSQL_REDMINE_PASSWORD
  encoding: utf8
""" > config/database.yml

    # redmine initialization
    gem install bundler
    cd /opt/redmine && bundle install --without development test
    
    # redmine population
    bundle exec rake generate_secret_token
    export RAILS_ENV=production
    bundle exec rake db:migrate
    bundle exec rake redmine:load_default_data
    rake redmine:plugins:migrate

fi
