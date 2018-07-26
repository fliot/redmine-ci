#!/bin/sh


service mysql start
service apache2 start

cd /opt/redmine
bundle exec rails server webrick -e production

service apache2 stop
service mysql stop
