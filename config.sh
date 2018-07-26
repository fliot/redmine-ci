#!/bin/sh

export MYSQL_ROOT_PASSWORD=mypassword
export MYSQL_REDMINE_PASSWORD=mypass
export REDMINE_LANG=fr

# apache configuration
cd /etc/apache2/sites-enabled
a2enmod alias cgid perl proxy proxy_http rewrite

rm 000-default.conf
echo """
<VirtualHost *:80>
    ServerName server
    ServerAlias www.server
    
    RewriteEngine on
    RewriteCond %{REQUEST_URI} ^/$
    RewriteRule (.*) /redmine/ [R=301]
    
    ProxyPass /images/ http://localhost:3000/images/
    ProxyPassReverse /images/ http://localhost:3000/images/
    
    ProxyPass /javascripts/ http://localhost:3000/javascripts/
    ProxyPassReverse /javascripts/ http://localhost:3000/javascripts/

    ProxyPass /plugin_assets/ http://localhost:3000/plugin_assets/
    ProxyPassReverse /plugin_assets/ http://localhost:3000/plugin_assets/

    ProxyPass /redmine/ http://localhost:3000/redmine/
    ProxyPassReverse /redmine/ http://localhost:3000/redmine/
    
    ProxyPass /stylesheets/ http://localhost:3000/stylesheets/
    ProxyPassReverse /stylesheets/ http://localhost:3000/stylesheets/
    
    ProxyPass /themes/ http://localhost:3000/themes/
    ProxyPassReverse /themes/ http://localhost:3000/themes/
    
    
    SetEnv GIT_PROJECT_ROOT /data/git
    SetEnv GIT_HTTP_EXPORT_ALL
    ScriptAlias /git/ /usr/lib/git-core/git-http-backend/
    
    PerlLoadModule Apache::Redmine
    

    <Location /git>
        Order allow,deny
        Allow from all
        
        AuthType Basic
        AuthName \"Git repositories\"
        Require valid-user
        AuthUserFile /dev/null
        
        PerlAccessHandler Apache::Authn::Redmine::access_handler
        PerlAuthenHandler Apache::Authn::Redmine::authen_handler
        
        RedmineDSN \"DBI:mysql:database=redmine;host=localhost;mysql_socket=/var/run/mysqld/mysqld.sock\"
        RedmineDbUser \"redmine\"
        RedmineDbPass \"$MYSQL_REDMINE_PASSWORD\"
        
        #Enable Git Smart Http
        RedmineGitSmartHttp yes
    </Location>
    
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
    mkdir /data/git
    
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

    # redmine http prefix
    sed -i "s:Rails.application.initialize!::g" config/environment.rb
    echo """
RedmineApp::Application.routes.default_scope = \"/redmine\" 
# Initialize the Rails application
Rails.application.initialize!
""" >> config/environment.rb

    # redmine initialization
    gem install bundler
    cd /opt/redmine && bundle install --without development test
    
    # redmine population
    bundle exec rake generate_secret_token
    export RAILS_ENV=production
    bundle exec rake db:migrate
    bundle exec rake redmine:load_default_data
    rake redmine:plugins:migrate

    # redmine settings default
    echo """TRUNCATE TABLE settings;
INSERT INTO settings VALUES 
(1,'ui_theme','circle','2018-07-26 18:58:57'),
(2,'default_language','$REDMINE_LANG','2018-07-26 18:58:57'),
(3,'force_default_language_for_anonymous','0','2018-07-26 18:58:57'),
(4,'force_default_language_for_loggedin','0','2018-07-26 18:58:57'),
(5,'start_of_week','','2018-07-26 18:58:57'),
(6,'date_format','','2018-07-26 18:58:57'),
(7,'time_format','','2018-07-26 18:58:57'),
(8,'timespan_format','decimal','2018-07-26 18:58:57'),
(9,'user_format','firstname_lastname','2018-07-26 18:58:57'),
(10,'gravatar_enabled','0','2018-07-26 18:58:57'),
(11,'gravatar_default','','2018-07-26 18:58:57'),
(12,'thumbnails_enabled','0','2018-07-26 18:58:57'),
(13,'thumbnails_size','100','2018-07-26 18:58:57'),
(14,'new_item_menu_tab','2','2018-07-26 18:58:57'),
(15,'plugin_redmine_create_git','---\nrepo_path: \"/data/git\"\ngitignore: \"# ignore all logs\\r\\n*.log\"\nbranches: \'\'\nrepo_url: http://localhost:8080/git/\n','2018-07-26 19:02:44'),
(16,'rest_api_enabled','1','2018-07-26 19:05:24'),
(17,'jsonp_enabled','0','2018-07-26 19:05:24');
""" | mysql -u root --password=$MYSQL_ROOT_PASSWORD redmine

fi
