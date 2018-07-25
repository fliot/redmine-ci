FROM ubuntu

# system
ENV DEBIAN_FRONTEND teletype
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y apache2 curl git ruby rails mysql-server net-tools unzip wget

# ruby bundler deps
RUN apt-get install -y build-essential imagemagick liblzma-dev libmagickwand-dev libmysqlclient-dev patch ruby-dev zlib1g-dev   

# redmine middleware
WORKDIR /root
RUN wget https://www.redmine.org/releases/redmine-3.4.6.tar.gz
RUN tar -zxvf redmine-3.4.6.tar.gz
RUN mv redmine-3.4.6 /opt

# apply configuration
ADD config.sh /opt
RUN sh /opt/config.sh

# redmine plugins and themes
RUN cd /opt/redmine-* && cd plugins && git clone https://github.com/easysoftware/redmine_social_sign_in.git
RUN cd /opt/redmine-* && cd public/themes && git clone https://github.com/Nitrino/flatly_light_redmine.git
# https://www.redmineup.com/pages/themes/circle
RUN cd /opt/redmine-* && cd public/themes && wget http://support.netinteractive.pl/themes/circle_theme-2_1_3.zip && unzip circle_theme-2_1_3.zip
RUN cd /opt/redmine-* && cd plugins && git clone https://github.com/mikitex70/redmine_drawio.git
# https://www.redmine.org/plugins/mindmap-plugin
RUN cd /opt/redmine-* && cd plugins &&  wget https://packages.easyredmine.com/packages/free_easy_wbs-7577f618e0d8f65bf9179be3ad82c45a.zip && unzip free_easy_wbs-7577f618e0d8f65bf9179be3ad82c45a.zip
# http://www.redmine.org/plugins/custom-workflows
RUN cd /opt/redmine-* && cd plugins && git clone http://github.com/anteo/redmine_custom_workflows.git

# https://docs.bitnami.com/general/apps/redmine/#How_to_configure_Redmine_for_advanced_integration_with_Git

# remine init
RUN gem install bundler
RUN service mysql start &&\
        cd /opt/redmine-* &&\
        bundle install --without development test &&\
        bundle exec rake generate_secret_token &&\
        export RAILS_ENV=production &&\
        bundle exec rake db:migrate &&\
        export REDMINE_LANG=fr &&\
        bundle exec rake redmine:load_default_data &&\
        service mysql stop

ADD script.sh /opt

EXPOSE 80

VOLUME ["/var/log"]

CMD ["/bin/sh", "/opt/script.sh"]
#CMD ["/bin/bash","-l"]
