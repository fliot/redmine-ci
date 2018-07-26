FROM ubuntu

############################################################################################################
# system
############################################################################################################
ENV DEBIAN_FRONTEND teletype
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y apache2 curl git libapache2-mod-passenger mysql-server net-tools rails ruby unzip wget

############################################################################################################
# ruby bundler deps
############################################################################################################
RUN apt-get install -y build-essential imagemagick liblzma-dev libmagickwand-dev libmysqlclient-dev patch ruby-dev zlib1g-dev   

############################################################################################################
# redmine middleware
############################################################################################################
WORKDIR /root
RUN wget https://www.redmine.org/releases/redmine-3.4.6.tar.gz
RUN tar -zxvf redmine-3.4.6.tar.gz
RUN mv redmine-3.4.6 /opt/
RUN ln -s /opt/redmine-* /opt/redmine

############################################################################################################
# redmine plugins
############################################################################################################
# https://github.com/easysoftware/redmine_social_sign_in
RUN cd /opt/redmine && cd plugins && git clone https://github.com/easysoftware/redmine_social_sign_in.git

# https://github.com/mikitex70/redmine_drawio
RUN cd /opt/redmine && cd plugins && git clone https://github.com/mikitex70/redmine_drawio.git

# https://www.redmine.org/plugins/mindmap-plugin
RUN cd /opt/redmine && cd plugins &&  wget https://packages.easyredmine.com/packages/free_easy_wbs-7577f618e0d8f65bf9179be3ad82c45a.zip && unzip free_easy_wbs-7577f618e0d8f65bf9179be3ad82c45a.zip

# http://www.redmine.org/plugins/custom-workflows
RUN cd /opt/redmine && cd plugins && git clone http://github.com/anteo/redmine_custom_workflows.git
RUN echo "#admin-menu a.custom-workflows { background-position-x:0%; background-position-y: 50%; background-repeat-x: no-repeat; background-repeat-y: no-repeat; padding-left: 20px; text-decoration-line: underline; }" >> /opt/redmine/plugins/redmine_custom_workflows/assets/stylesheets/style.css

# https://github.com/jbox-web/redmine_jenkins
RUN cd /opt/redmine && cd plugins && git clone https://github.com/jbox-web/redmine_bootstrap_kit.git
RUN cd /opt/redmine && cd plugins && git clone https://github.com/jbox-web/redmine_jenkins.git
RUN cd /opt/redmine && sed -i "s!gem 'jenkins_api_client', '~> 1.3.0'!gem 'jenkins_api_client', '~> 1.5.2'!g" plugins/redmine_jenkins/Gemfile

# https://github.com/martin-denizet/redmine_create_git
RUN cd /opt/redmine && cd plugins && git clone https://github.com/martin-denizet/redmine_create_git.git

############################################################################################################
# redmine themes
############################################################################################################
# https://github.com/Nitrino/flatly_light_redmine
RUN cd /opt/redmine && cd public/themes && git clone https://github.com/Nitrino/flatly_light_redmine.git

# https://www.redmineup.com/pages/themes/circle
RUN cd /opt/redmine && cd public/themes && wget http://support.netinteractive.pl/themes/circle_theme-2_1_3.zip && unzip circle_theme-2_1_3.zip

############################################################################################################
# TODO : jenkins
############################################################################################################
# TODO : jenkins redmine plugin
############################################################################################################
# git clone https://github.com/jenkinsci/redmine-plugin.git

############################################################################################################
# remine init
############################################################################################################
ADD config.sh /opt
RUN sh /opt/config.sh

############################################################################################################
# git with redmine authentication
############################################################################################################
RUN apt-get install -y libapache2-mod-perl2 libdbi-perl libdbd-mysql-perl
RUN cp /opt/redmine-3.4.6/extra/svn/Redmine.pm /usr/lib/x86_64-linux-gnu/perl5/5.26/Apache/

ADD git-init.sh /opt
ADD script.sh /opt

EXPOSE 80

VOLUME ["/data"]

CMD ["/bin/sh", "/opt/script.sh"]
